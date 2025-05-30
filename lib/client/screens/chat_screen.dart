import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/chat_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _otherUserData;
  final ScrollController _scrollController = ScrollController();
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = false;
  String? _editingMessageId;

  static const String _appId = '0de2f19534204d55afbaae4d90f6677a';
  String _channelName = '';

  @override
  void initState() {
    super.initState();
    _fetchOtherUserData();
    _initAgora();
    _channelName = 'voice_${widget.userId}_${FirebaseAuth.instance.currentUser?.uid ?? 'unknown'}';
  }

  Future<void> _fetchOtherUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (userDoc.exists && mounted) {
      setState(() {
        _otherUserData = userDoc.data();
      });
    }
  }

  Future<void> _initAgora() async {
    try {
      await [Permission.microphone, Permission.camera].request();
      if (await Permission.microphone.isDenied || await Permission.camera.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền micro và camera để gọi')),
        );
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Người dùng khác đã tham gia cuộc gọi')),
            );
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Người dùng khác đã rời cuộc gọi')),
            );
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            setState(() {
              _isJoined = false;
              _isVideoEnabled = false;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi gọi: $msg')),
            );
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khởi tạo gọi thất bại: $e')),
      );
    }
  }

  Future<void> _startVoiceCall() async {
    if (_engine == null || _isJoined) return;
    try {
      await _engine!.enableAudio();
      await _engine!.disableVideo();
      await _engine!.joinChannel(
        token: '',
        channelId: _channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
      setState(() {
        _isVideoEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu cuộc gọi thoại')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bắt đầu gọi thoại thất bại: $e')),
      );
    }
  }

  Future<void> _startVideoCall() async {
    if (_engine == null || _isJoined) return;
    try {
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.joinChannel(
        token: '',
        channelId: _channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
      setState(() {
        _isVideoEnabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu cuộc gọi video')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bắt đầu gọi video thất bại: $e')),
      );
    }
  }

  Future<void> _toggleMute() async {
    if (_engine == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine!.muteLocalAudioStream(_isMuted);
  }

  Future<void> _endCall() async {
    if (_engine == null || !_isJoined) return;
    await _engine!.leaveChannel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuộc gọi đã kết thúc')),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    try {
      if (_editingMessageId != null) {
        _chatService.editMessage(
          widget.userId,
          _editingMessageId!,
          _messageController.text.trim(),
        );
        setState(() {
          _editingMessageId = null;
        });
      } else {
        _chatService.sendMessage(
          widget.userId,
          _messageController.text.trim(),
          'text',
        );
      }
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi tin nhắn thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendImage() async {
    try {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền truy cập bộ nhớ để chọn ảnh')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng chưa đăng nhập')),
        );
        return;
      }

      final file = File(image.path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File ảnh không tồn tại')),
        );
        return;
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      if (base64Image.length > 700000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn')),
        );
        return;
      }

      await _chatService.sendMessage(
        widget.userId,
        'Đã gửi một ảnh',
        'image',
        fileUrl: base64Image,
      );
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi ảnh thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewFullImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Lỗi tải ảnh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageGallery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thư viện ảnh'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getMessages(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Lỗi khi tải ảnh'));
              }
              final images = snapshot.data
                      ?.where((msg) => msg['type'] == 'image')
                      .toList() ??
                  [];
              if (images.isEmpty) {
                return const Center(child: Text('Không tìm thấy ảnh'));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final timestamp = (image['timestamp'] as Timestamp?)?.toDate();
                  final timeString = timestamp != null
                      ? '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                      : '';
                  return GestureDetector(
                    onTap: () => _viewFullImage(context, image['fileUrl']),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(image['fileUrl']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeString,
                          style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _shareFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chia sẻ file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nhập URL file (mô phỏng)',
              ),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              try {
                _chatService.sendMessage(
                  widget.userId,
                  'Đã chia sẻ file: sample.pdf',
                  'file',
                  fileUrl: 'https://example.com/sample.pdf',
                );
                Navigator.pop(context);
                _scrollToBottom();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chia sẻ file thất bại: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Chia sẻ'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageOptions(BuildContext context, String messageId, String message, bool isMe) {
    if (!isMe) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit message'),
              onTap: () {
                setState(() {
                  _editingMessageId = messageId;
                  _messageController.text = message;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Recall message'),
              onTap: () {
                _chatService.recallMessage(widget.userId, messageId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go("/message");
          },
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: _otherUserData?['avatarUrl']?.isNotEmpty == true
                      ? NetworkImage(_otherUserData!['avatarUrl'])
                      : null,
                  child: _otherUserData?['avatarUrl']?.isNotEmpty != true
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _otherUserData?['isOnline'] == true
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              _otherUserData?['name'] ?? widget.userId,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isJoined ? Icons.call_end : Icons.call,
              color: _isJoined ? Colors.red : Colors.black,
            ),
            onPressed: _isJoined ? _endCall : _startVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            onPressed: _isJoined ? _endCall : _startVideoCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'gallery') {
                _showImageGallery();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'gallery',
                  child: Text('Xem thư viện ảnh'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isJoined)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.black,
                    ),
                    onPressed: _toggleMute,
                  ),
                  if (_isVideoEnabled)
                    IconButton(
                      icon: Icon(
                        _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        color: _isVideoEnabled ? Colors.black : Colors.red,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isVideoEnabled = !_isVideoEnabled;
                        });
                        if (_isVideoEnabled) {
                          await _engine!.enableVideo();
                          await _engine!.enableLocalVideo(true);
                        } else {
                          await _engine!.disableVideo();
                        }
                      },
                    ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    onPressed: _endCall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải tin nhắn'));
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender'] == 'You';
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
                    final timeString = timestamp != null
                        ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                        : '';
                    final messageId = snapshot.data![index]['id'];

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(context, messageId, message['message'], isMe),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: message['type'] == 'image'
                              ? Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _viewFullImage(context, message['fileUrl']);
                                      },
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                                          maxHeight: 200,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.memory(
                                            base64Decode(message['fileUrl']),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Text('Lỗi tải ảnh'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['message']!,
                                      style: const TextStyle(fontSize: 12.0),
                                    ),
                                    Text(
                                      timeString,
                                      style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                                    ),
                                  ],
                                )
                              : message['type'] == 'file'
                                  ? Column(
                                      crossAxisAlignment:
                                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            print('Mở file: ${message['fileUrl']}');
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message['message']!,
                                                style: const TextStyle(fontSize: 16.0),
                                              ),
                                              Text(
                                                message['fileUrl']!,
                                                style: const TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          timeString,
                                          style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['message']!,
                                          style: const TextStyle(fontSize: 16.0),
                                        ),
                                        Text(
                                          timeString,
                                          style: const TextStyle(fontSize: 10.0, color: Colors.grey),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _shareFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null ? 'Editing message...' : 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      // fillColor: Colors.grey[200],
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}
//màn hình chat