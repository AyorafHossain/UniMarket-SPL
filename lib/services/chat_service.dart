import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper to validate Firestore document ID
  bool isValidId(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  // Helper to validate ChatRoomModel
  bool _isValidChatRoom(ChatRoomModel room, String currentUserId) {
    if (!isValidId(room.id)) {
      debugPrint('Skipping invalid chat document: chatId is empty');
      return false;
    }
    
    final isBuyer = currentUserId == room.buyerId;
    final otherUserId = isBuyer ? room.sellerId : room.buyerId;
    
    if (!isValidId(otherUserId)) {
      debugPrint('Skipping invalid chat ${room.id}: otherUserId is empty. buyerId=${room.buyerId}, sellerId=${room.sellerId}');
      return false;
    }
    
    if (room.participantIds.isEmpty) {
      debugPrint('Skipping invalid chat ${room.id}: participantIds list is empty');
      return false;
    }

    return true;
  }

  // Stream active chat rooms for a user
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    if (!isValidId(userId)) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => ChatRoomModel.fromMap(doc.data()))
              .where((room) => _isValidChatRoom(room, userId) && !room.deletedFor.contains(userId))
              .toList();

          // Sort in memory by lastMessageTime descending (nulls at the end)
          rooms.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          return rooms;
        });
  }

  // Stream real-time messages for a chat room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    if (!isValidId(chatRoomId)) {
      debugPrint('Skipping invalid getMessages: chatRoomId is empty');
      return Stream.value([]);
    }
    
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Send a message and update chat room metadata atomically
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    
    if (!isValidId(chatRoomId) || !isValidId(senderId) || !isValidId(receiverId)) {
      debugPrint('Skipping sendMessage: invalid parameters (chatRoomId: $chatRoomId, senderId: $senderId, receiverId: $receiverId)');
      return;
    }

    final messageDoc = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    final now = DateTime.now();
    final message = MessageModel(
      id: messageDoc.id,
      senderId: senderId,
      receiverId: receiverId,
      message: text.trim(),
      timestamp: now,
    );

    // Atomically save message and update last message info in chat room
    final batch = _firestore.batch();
    batch.set(messageDoc, message.toMap());
    batch.update(_firestore.collection('chat_rooms').doc(chatRoomId), {
      'lastMessage': text.trim(),
      'lastMessageSenderId': senderId,
      'lastMessageTime': Timestamp.fromDate(now),
      'deletedFor': FieldValue.arrayRemove([senderId, receiverId]),
    });

    await batch.commit();

    // Create a notification for the receiver
    final notificationService = NotificationService();
    await notificationService.createNotification(
      userId: receiverId,
      type: 'chat_message',
      title: 'New Message',
      body: text.trim(),
      data: {
        'chatId': chatRoomId,
        'senderId': senderId,
      },
    );
  }

  // Send a media message and update chat room metadata atomically
  Future<void> sendMediaMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String type, // 'image', 'video', 'audio', 'file'
    required String mediaUrl,
    String? fileName,
    int? fileSize,
    int? duration,
  }) async {
    if (!isValidId(chatRoomId) || !isValidId(senderId) || !isValidId(receiverId)) {
      debugPrint('Skipping sendMediaMessage: invalid parameters');
      return;
    }
    
    if (mediaUrl.trim().isEmpty) return;

    final messageDoc = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    final now = DateTime.now();
    
    String displayMessage = '';
    if (type == 'image') {
      displayMessage = 'Sent a photo';
    } else if (type == 'video') {
      displayMessage = 'Sent a video';
    } else if (type == 'audio') {
      displayMessage = 'Sent a voice message';
    } else if (type == 'file') {
      displayMessage = 'Sent a file';
    } else {
      displayMessage = 'Sent an attachment';
    }

    final message = MessageModel(
      id: messageDoc.id,
      senderId: senderId,
      receiverId: receiverId,
      message: displayMessage,
      timestamp: now,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
    );

    // Atomically save message and update last message info in chat room
    final batch = _firestore.batch();
    batch.set(messageDoc, message.toMap());
    batch.update(_firestore.collection('chat_rooms').doc(chatRoomId), {
      'lastMessage': displayMessage,
      'lastMessageSenderId': senderId,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageType': type,
      'deletedFor': FieldValue.arrayRemove([senderId, receiverId]),
    });

    await batch.commit();

    // Create a notification for the receiver
    final notificationService = NotificationService();
    await notificationService.createNotification(
      userId: receiverId,
      type: 'chat_message',
      title: 'New Message',
      body: displayMessage,
      data: {
        'chatId': chatRoomId,
        'senderId': senderId,
      },
    );
  }

  // Get or create a chat room when starting a chat about a product
  Future<ChatRoomModel> createOrGetChatRoom({
    required String productId,
    required String productTitle,
    required double productPrice,
    required String productImageUrl,
    required UserModel buyer,
    required UserModel seller,
  }) async {
    if (!isValidId(productId) || !isValidId(buyer.id) || !isValidId(seller.id)) {
      throw Exception('Invalid parameters to create chat room');
    }
    
    final String chatRoomId = '${productId}_${buyer.id}';
    final docRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      return ChatRoomModel.fromMap(docSnap.data()!);
    } else {
      final newRoom = ChatRoomModel(
        id: chatRoomId,
        buyerId: buyer.id,
        buyerName: buyer.name,
        buyerPic: buyer.profilePic,
        sellerId: seller.id,
        sellerName: seller.name,
        sellerPic: seller.profilePic,
        productId: productId,
        productTitle: productTitle,
        productPrice: productPrice,
        productImageUrl: productImageUrl,
        lastMessage: '',
        lastMessageSenderId: '',
        lastMessageTime: null,
        participantIds: [buyer.id, seller.id],
        deletedFor: [],
      );

      await docRef.set(newRoom.toMap());
      return newRoom;
    }
  }

  // Update a user's online status in Firestore
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    if (!isValidId(userId)) return;
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
      });
    } catch (e) {
      debugPrint('ChatService: updateOnlineStatus error for $userId: $e');
    }
  }

  // Stream a specific user's model in real-time (to monitor active status dot)
  Stream<UserModel?> getUserStream(String userId) {
    if (!isValidId(userId)) {
      debugPrint('Skipping getUserStream: userId is empty');
      return Stream.value(null);
    }
    
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Delete message for current user
  Future<void> deleteMessageForMe({
    required String chatRoomId,
    required String messageId,
    required String currentUserId,
  }) async {
    if (!isValidId(chatRoomId) || !isValidId(messageId) || !isValidId(currentUserId)) {
      debugPrint('Skipping deleteMessageForMe: invalid parameters');
      return;
    }
    
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([currentUserId])
      });
    } catch (e) {
      debugPrint('ChatService: deleteMessageForMe error: $e');
    }
  }

  // Delete message for everyone
  Future<void> deleteMessageForEveryone({
    required String chatRoomId,
    required String messageId,
    required String currentUserId,
  }) async {
    if (!isValidId(chatRoomId) || !isValidId(messageId) || !isValidId(currentUserId)) {
      debugPrint('Skipping deleteMessageForEveryone: invalid parameters');
      return;
    }
    
    try {
      final now = DateTime.now();
      
      // Update message
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'message': '',
        'mediaUrl': '',
        'fileName': '',
        'type': 'deleted',
        'deletedAt': Timestamp.fromDate(now),
        'deletedBy': currentUserId,
      });

      // Check if this was the last message, and if so, update the chat room's last message
      final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      if (chatRoomDoc.exists) {
        // Here we could query the most recent message to be accurate, or just update to "Message deleted"
        // The simplest approach as requested is to update to "Message deleted" if it was the last message.
        // We'll query the latest non-deleted message to see what the last message should be, 
        // or just set it to 'Message deleted' if it's too complex.
        
        final messagesQuery = await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
            
        if (messagesQuery.docs.isNotEmpty) {
          final lastMessageData = messagesQuery.docs.first.data();
          if (lastMessageData['id'] == messageId || (lastMessageData['isDeleted'] == true)) {
             await _firestore.collection('chat_rooms').doc(chatRoomId).update({
                'lastMessage': 'Message deleted',
             });
          }
        }
      }
    } catch (e) {
      debugPrint('ChatService: deleteMessageForEveryone error: $e');
    }
  }

  // Delete chat for current user
  Future<void> deleteChatForUser({
    required String chatRoomId,
    required String currentUserId,
  }) async {
    if (!isValidId(chatRoomId) || !isValidId(currentUserId)) {
      debugPrint('Skipping deleteChatForUser: invalid parameters');
      return;
    }

    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayUnion([currentUserId])
      });
    } catch (e) {
      debugPrint('ChatService: deleteChatForUser error: $e');
      rethrow;
    }
  }
}
