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
import 'package:image/image.dart' as img;

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _groupData;
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
    _fetchGroupData();
    _initAgora();
    _channelName = 'group_${widget.groupId}';
  }

  Future<void> _fetchGroupData() async {
    final groupDoc =
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (groupDoc.exists && mounted) {
      setState(() {
        _groupData = groupDoc.data();
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
      await _engine!.initialize(
        const RtcEngineContext(
          appId: _appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thành viên khác đã tham gia cuộc gọi')),
            );
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thành viên khác đã rời cuộc gọi')),
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
        const SnackBar(content: Text('Đã bắt đầu cuộc gọi thoại nhóm')),
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
        const SnackBar(content: Text('Đã bắt đầu cuộc gọi video nhóm')),
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
      const SnackBar(content: Text('Cuộc gọi nhóm đã kết thúc')),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    try {
      if (_editingMessageId != null) {
        _chatService.editGroupMessage(
          widget.groupId,
          _editingMessageId!,
          _messageController.text.trim(),
        );
        setState(() {
          _editingMessageId = null;
        });
      } else {
        _chatService.sendGroupMessage(
          widget.groupId,
          _messageController.text.trim(),
          'text',
        );
      }
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi tin nhắn thất bại: $e'),
          backgroundColor: Colors.red,
        ),
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

      await _chatService.sendGroupMessage(
        widget.groupId,
        'Đã gửi một ảnh',
        'image',
        fileUrl: base64Image,
      );
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi ảnh thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateGroupAvatar() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người dùng chưa đăng nhập')),
      );
      return;
    }

    // Kiểm tra quyền: Chỉ người tạo nhóm được thay đổi avatar
    if (_groupData?['createdBy'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ người tạo nhóm mới có thể thay đổi avatar')),
      );
      return;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền truy cập bộ nhớ để chọn ảnh')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File ảnh không tồn tại')),
      );
      return;
    }

    // Đọc và nén ảnh
    final bytes = await file.readAsBytes();
    var decodedImage = img.decodeImage(bytes); // Sử dụng decodeImage thay vì decodeImageFromList
    if (decodedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể giải mã ảnh, vui lòng thử ảnh khác')),
      );
      return;
    }

    // Thay đổi kích thước ảnh (giới hạn chiều rộng tối đa 800px, giữ tỷ lệ)
    var resizedImage = img.copyResize(
      decodedImage,
      width: decodedImage.width > 800 ? 800 : decodedImage.width,
      interpolation: img.Interpolation.average,
    );

    // Nén ảnh với chất lượng 80%
    final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
    final base64Image = base64Encode(compressedBytes);

    if (base64Image.length > 700000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ảnh vẫn quá lớn sau khi nén, vui lòng chọn ảnh nhỏ hơn'),
        ),
      );
      return;
    }

    // Cập nhật avatarUrl trong tài liệu nhóm
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'avatarUrl': base64Image,
    });

    // Làm mới _groupData để cập nhật giao diện
    await _fetchGroupData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật avatar nhóm thành công')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cập nhật avatar thất bại: $e'),
        backgroundColor: Colors.red,
      ),
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
        title: const Text('Thư viện ảnh nhóm'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getGroupMessages(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Lỗi khi tải ảnh'));
              }
              final images = snapshot.data?.where((msg) => msg['type'] == 'image').toList() ?? [];
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
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
              decoration: const InputDecoration(hintText: 'Nhập URL file (mô phỏng)'),
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
                _chatService.sendGroupMessage(
                  widget.groupId,
                  'Đã chia sẻ file: sample.pdf',
                  'file',
                  fileUrl: 'https://example.com/sample.pdf',
                );
                Navigator.pop(context);
                _scrollToBottom();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chia sẻ file thất bại: $e'),
                    backgroundColor: Colors.red,
                  ),
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
                _chatService.recallGroupMessage(widget.groupId, messageId);
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
    final user = FirebaseAuth.instance.currentUser;
    final isCreator = _groupData?['createdBy'] == user?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            context.go("/message");
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _groupData?['avatarUrl']?.isNotEmpty == true
                  ? (_groupData!['avatarUrl'].startsWith('assets/')
                      ? AssetImage(_groupData!['avatarUrl'])
                      : MemoryImage(base64Decode(_groupData!['avatarUrl'])))
                  : const AssetImage('assets/group.jpg') as ImageProvider,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupData?['name'] ?? 'Nhóm không tên',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<List<String>>(
                  future: _getMemberNames(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Đang tải...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        'Lỗi tải thành viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    final names = snapshot.data!;
                    final displayText = names.length > 1 ? '${names[0]}...' : names[0];
                    return Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isJoined ? Icons.call_end : Icons.call,
              color: _isJoined ? Colors.red : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _isJoined ? _endCall : _startVoiceCall,
          ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _isJoined ? _endCall : _startVideoCall,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onSelected: (value) {
              if (value == 'gallery') {
                _showImageGallery();
              } else if (value == 'details') {
                context.go('/message/group/${widget.groupId}/details');
              } else if (value == 'change_avatar' && isCreator) {
                _updateGroupAvatar();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'gallery',
                  child: Text('Xem thư viện ảnh'),
                ),
                const PopupMenuItem<String>(
                  value: 'details',
                  child: Text('Xem chi tiết nhóm'),
                ),
                if (isCreator)
                  const PopupMenuItem<String>(
                    value: 'change_avatar',
                    child: Text('Thay đổi avatar nhóm'),
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
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _toggleMute,
                  ),
                  if (_isVideoEnabled)
                    IconButton(
                      icon: Icon(
                        _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        color: _isVideoEnabled ? Theme.of(context).colorScheme.onSurface : Colors.red,
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
              stream: _chatService.getGroupMessages(widget.groupId),
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
                    final isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
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
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                FutureBuilder<String>(
                                  future: _getSenderName(message['senderId']),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    );
                                  },
                                ),
                              if (message['type'] == 'image')
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
                                        errorBuilder: (context, error, stackTrace) => const Text('Lỗi tải ảnh'),
                                      ),
                                    ),
                                  ),
                                ),
                              if (message['type'] == 'image') const SizedBox(height: 4),
                              Text(
                                message['message']!,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                timeString,
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getSenderName(String senderId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    return userDoc.data()?['name'] ?? 'Unknown';
  }

  Future<List<String>> _getMemberNames() async {
    final members = List<String>.from(_groupData?['members'] ?? []);
    List<String> names = [];
    for (String memberId in members) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
      names.add(userDoc.data()?['name'] ?? 'Unknown');
    }
    return names;
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
//chat nhóm