import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';

// Top-level function to handle background messages (required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Local notifications for foreground display
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Request permissions
    await requestPermission();

    // 2. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error decoding notification payload: $e');
          }
        }
      },
    );

    // 3. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // 5. Handle app opened from background state via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data);
    });

    // 6. Handle app opened from terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Delay navigation slightly to ensure app is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        handleNotificationTap(initialMessage.data);
      });
    }

    // 7. Get and save token if user is logged in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        getAndSaveToken(user.uid);
      }
    });
    
    // Listen to token refresh
    _fcm.onTokenRefresh.listen((String token) {
      final user = _auth.currentUser;
      if (user != null) {
        _saveTokenToFirestore(user.uid, token);
      }
    });
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> getAndSaveToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  void handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      showLocalNotification(message);
    }
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'unimarket_channel_id',
      'UniMarket Notifications',
      channelDescription: 'General notifications for UniMarket',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    
    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;
    
    // Note: The actual implementation would depend on the routing strategy
    // For now, we will push to specific screens using named routes or pushing directly.
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    
    switch (type) {
      case 'chat_message':
        // Navigate to chat screen
        // Example: navigator.pushNamed(AppConstants.chatRoute, arguments: data['chatId']);
        break;
      case 'wishlist_price_drop':
        if (data['productId'] != null) {
          final dummyProduct = ProductModel(
            productId: data['productId'],
            sellerId: '',
            title: data['productTitle'] ?? 'Product',
            description: '',
            price: (data['newPrice'] ?? 0).toDouble(),
            category: 'Other',
            condition: 'Good',
            imageUrls: [],
            createdAt: DateTime.now(),
            stockQuantity: 1,
          );
          navigator.pushNamed(AppConstants.productDetailsRoute, arguments: dummyProduct);
        }
        break;
      case 'order_update':
      case 'rent_request':
      case 'exchange_request':
        // Navigate to respective screens
        break;
      default:
        // Navigate to notification center
        break;
    }
  }

  // --- Firestore Notification Center Logic ---

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }
  
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
  
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unreadDocs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  // Note: Real push sending should be done via Firebase Cloud Functions.
  // For this initial setup, we only create the Firestore document.
  // A Cloud Function would listen to new documents in 'notifications' 
  // and trigger the actual FCM send to the user's fcmToken.
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
