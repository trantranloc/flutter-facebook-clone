import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/chat_service.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final List<String>? members;

  const ChatScreen({super.key, required this.userId, this.members});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _otherUserData;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserData();
  }

  // Lấy thông tin người dùng khác
  Future<void> _fetchOtherUserData() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    if (userDoc.exists) {
      setState(() {
        _otherUserData = userDoc.data();
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.userId,
        _messageController.text.trim(),
        'text',
      );
      _messageController.clear();
      // Cuộn xuống tin nhắn mới nhất (tuỳ chọn)
      // ScrollController có thể được thêm nếu cần
    }
  }

  void _shareFile() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Share File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter file URL (mock)',
                  ),
                  onChanged: (value) {
                    // Giả lập nhập URL file
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _chatService.sendMessage(
                    widget.userId,
                    'Shared a file: sample.pdf',
                    'file',
                    fileUrl: 'https://example.com/sample.pdf',
                  );
                  Navigator.pop(context);
                },
                child: const Text('Share'),
              ),
            ],
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
                  backgroundImage:
                      _otherUserData?['avatarUrl']?.isNotEmpty == true
                          ? NetworkImage(_otherUserData!['avatarUrl'])
                          : null,
                  child:
                      _otherUserData?['avatarUrl']?.isNotEmpty != true
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
                      color:
                          _otherUserData?['isOnline'] == true
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
        actions:
            widget.members != null && widget.members!.isNotEmpty
                ? [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) {
                      // Xử lý hành động menu
                    },
                    itemBuilder: (BuildContext context) {
                      return widget.members!.map((member) {
                        return PopupMenuItem<String>(
                          value: member,
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.grey,
                                    child: Text(member[0]),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            _otherUserData?['isOnline'] == true
                                                ? Colors.green
                                                : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(member),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ]
                : [],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true, // Hiển thị tin nhắn mới nhất ở dưới
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender'] == 'You';
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child:
                            message['type'] == 'file'
                                ? InkWell(
                                  onTap: () {
                                    print(
                                      'Opening file: ${message['fileUrl']}',
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
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
                                )
                                : Text(
                                  message['message']!,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _shareFile,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  onPressed: () {
                    // Action to open camera
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onSubmitted:
                        (value) => _sendMessage(), // Gửi khi nhấn Enter
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
    super.dispose();
  }
}
