import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../services/chat_service.dart';
import '../../services/product_service.dart';
import '../../services/cloudinary_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/currency_formatter.dart';
import 'video_player_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isSending = false;
  bool _isRecording = false;
  String? _recordingPath;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productService = ProductService();
      final product = await productService.getProduct(widget.chatRoom.productId);
      if (mounted && product != null) {
        setState(() {
          _product = product;
        });
      }
    } catch (e) {
      debugPrint('Error loading product for smart replies: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _sendMessage(String currentUserId, String otherUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: currentUserId,
        receiverId: otherUserId,
        text: text,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendMedia(File file, String type, String currentUserId, String otherUserId, {String? fileName}) async {
    setState(() {
      _isSending = true;
    });
    // Pop the bottom sheet if it's open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      String mediaUrl = '';
      if (type == 'image') {
        mediaUrl = await _cloudinaryService.uploadImage(imageFile: file, folder: 'chat_images');
      } else if (type == 'video') {
        mediaUrl = await _cloudinaryService.uploadVideo(videoFile: file, folder: 'chat_videos');
      } else if (type == 'audio') {
        mediaUrl = await _cloudinaryService.uploadAudio(audioFile: file, folder: 'chat_audio');
      } else if (type == 'file') {
        mediaUrl = await _cloudinaryService.uploadFile(file: file, folder: 'chat_files');
      }

      await _chatService.sendMediaMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: currentUserId,
        receiverId: otherUserId,
        type: type,
        mediaUrl: mediaUrl,
        fileName: fileName ?? file.path.split('/').last,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading $type: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showAttachmentSheet(String currentUserId, String otherUserId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.pink, () async {
                final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  _sendMedia(File(photo.path), 'image', currentUserId, otherUserId);
                }
              }),
              _buildAttachmentOption(Icons.image, 'Gallery', Colors.purple, () async {
                final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  _sendMedia(File(image.path), 'image', currentUserId, otherUserId);
                }
              }),
              _buildAttachmentOption(Icons.videocam, 'Video', Colors.orange, () async {
                final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  _sendMedia(File(video.path), 'video', currentUserId, otherUserId);
                }
              }),
              _buildAttachmentOption(Icons.insert_drive_file, 'File', Colors.blue, () async {
                FilePickerResult? result = await FilePicker.pickFiles();
                if (result != null && result.files.single.path != null) {
                  File file = File(result.files.single.path!);
                  _sendMedia(file, 'file', currentUserId, otherUserId, fileName: result.files.single.name);
                }
              }),
              _buildAttachmentOption(Icons.mic, 'Audio', Colors.red, () {
                Navigator.pop(context); // Close sheet
                _showRecordingDialog(currentUserId, otherUserId);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showRecordingDialog(String currentUserId, String otherUserId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Record Audio', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    size: 64,
                    color: _isRecording ? AppColors.error : AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? 'Recording...' : 'Tap record to start',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_isRecording) {
                      await _audioRecorder.stop();
                      _isRecording = false;
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_isRecording) {
                      // Start recording
                      if (await _audioRecorder.hasPermission()) {
                        final tempDir = await getTemporaryDirectory();
                        _recordingPath = '${tempDir.path}/audio_message.m4a';
                        await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
                        setDialogState(() {
                          _isRecording = true;
                        });
                      }
                    } else {
                      // Stop recording and send
                      final path = await _audioRecorder.stop();
                      setDialogState(() {
                        _isRecording = false;
                      });
                      if (context.mounted) Navigator.pop(context);
                      if (path != null) {
                        _sendMedia(File(path), 'audio', currentUserId, otherUserId);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
                  ),
                  child: Text(_isRecording ? 'Stop & Send' : 'Record', style: const TextStyle(color: AppColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSmartReplies() {
    if (_product == null) return const SizedBox.shrink();

    List<String> replies = [];
    final type = _product!.listingType;

    if (type == 'sell') {
      replies = [
        'Is it available?',
        'What is the last price?',
        'Is the condition good?',
        'Can I pick it from campus?',
        'Can you send more photos?',
      ];
    } else if (type == 'rent') {
      replies = [
        'Is it available?',
        'Is rent available?',
        'Can I pick it from campus?',
        'Can you send more photos?',
      ];
    } else if (type == 'exchange') {
      replies = [
        'Is it available?',
        'Are you open to exchange?',
        'Can I pick it from campus?',
        'Can you send more photos?',
      ];
    } else {
      replies = [
        'Is it available?',
        'What is the last price?',
        'Is the condition good?',
        'Can I pick it from campus?',
        'Can you send more photos?',
        'Is rent available?',
        'Are you open to exchange?',
      ];
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              replies[index],
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
            onPressed: () {
              _messageController.text = replies[index];
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  void _showDeleteOptions(MessageModel message, String currentUserId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete for me', style: GoogleFonts.inter(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.deleteMessageForMe(
                    chatRoomId: widget.chatRoom.id,
                    messageId: message.id,
                    currentUserId: currentUserId,
                  );
                },
              ),
              if (message.senderId == currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: Text('Delete for everyone', style: GoogleFonts.inter(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _chatService.deleteMessageForEveryone(
                      chatRoomId: widget.chatRoom.id,
                      messageId: message.id,
                      currentUserId: currentUserId,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.textPrimary),
                title: Text('Cancel', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.userProfile;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User profile not loaded.')),
      );
    }

    final isBuyer = currentUser.id == widget.chatRoom.buyerId;
    final otherUserId = isBuyer ? widget.chatRoom.sellerId : widget.chatRoom.buyerId;
    final otherUserName = isBuyer ? widget.chatRoom.sellerName : widget.chatRoom.buyerName;
    final otherUserPic = isBuyer ? widget.chatRoom.sellerPic : widget.chatRoom.buyerPic;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<UserModel?>(
          stream: _chatService.getUserStream(otherUserId),
          builder: (context, snapshot) {
            final otherUser = snapshot.data;
            final isOnline = otherUser?.isOnline ?? false;

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: otherUserPic.isNotEmpty
                          ? NetworkImage(otherUserPic)
                          : null,
                      child: otherUserPic.isEmpty
                          ? Text(
                              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isOnline) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isOnline ? 'Active now' : 'Offline',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isOnline ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Product Context Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray200, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppColors.gray100,
                      child: widget.chatRoom.productImageUrl.isNotEmpty
                          ? Image.network(
                              widget.chatRoom.productImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: AppColors.textLight),
                            )
                          : const Icon(Icons.image, color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chatRoom.productTitle.trim().isNotEmpty 
                              ? widget.chatRoom.productTitle 
                              : 'Product unavailable',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(widget.chatRoom.productPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatRoom.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  final allMessages = snapshot.data ?? [];
                  final messages = allMessages.where((m) => !(m.deletedFor?.contains(currentUser.id) ?? false)).toList();

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.forum_outlined, size: 64, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(
                            'Say hi to start the conversation!',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser.id;

                      Widget messageContent;
                      
                      if (message.isDeleted || message.type == 'deleted') {
                        messageContent = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            border: Border.all(color: AppColors.gray200),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block, size: 16, color: AppColors.textLight),
                              const SizedBox(width: 8),
                              Text(
                                'This message was deleted',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (message.type == 'image' && message.mediaUrl != null) {
                        messageContent = GestureDetector(
                          onTap: () => _launchUrl(message.mediaUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.mediaUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else if (message.type == 'video' && message.mediaUrl != null) {
                        final String thumbnailUrl = message.mediaUrl!
                            .replaceAll('.mp4', '.jpg')
                            .replaceAll('.mov', '.jpg');
                            
                        messageContent = GestureDetector(
                          onTap: () {
                            debugPrint('Opening video URL: ${message.mediaUrl}');
                            if (message.mediaUrl!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(mediaUrl: message.mediaUrl!),
                                ),
                              );
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  thumbnailUrl,
                                  width: 200,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 200,
                                    height: 150,
                                    color: Colors.black12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      } else if (message.type == 'audio' && message.mediaUrl != null) {
                        messageContent = _AudioPlayerBubble(url: message.mediaUrl!, isMe: isMe);
                      } else if (message.type == 'file' && message.mediaUrl != null) {
                        messageContent = GestureDetector(
                          onTap: () => _launchUrl(message.mediaUrl!),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary.withValues(alpha: 0.9) : AppColors.gray200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppColors.textPrimary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    message.fileName ?? 'Attachment',
                                    style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Text message
                        messageContent = Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : AppColors.gray200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            message.message,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: isMe ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => _showDeleteOptions(message, currentUser.id),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                messageContent,
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _formatTime(message.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Uploading Indicator
            if (_isSending)
              Container(
                padding: const EdgeInsets.all(8.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Sending...'),
                  ],
                ),
              ),

            _buildSmartReplies(),

            // Text Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAttachmentSheet(currentUser.id, otherUserId),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.add, color: AppColors.primary, size: 28),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: AppColors.textLight),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(currentUser.id, otherUserId),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inline Audio Player Widget
class _AudioPlayerBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerBubble({required this.url, required this.isMe});

  @override
  State<_AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<_AudioPlayerBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? AppColors.primary : AppColors.gray200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: widget.isMe ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.url));
              }
            },
            child: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: widget.isMe ? Colors.white : AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 2,
                    activeTrackColor: widget.isMe ? Colors.white : AppColors.primary,
                    inactiveTrackColor: widget.isMe ? Colors.white54 : AppColors.textLight,
                    thumbColor: widget.isMe ? Colors.white : AppColors.primary,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
