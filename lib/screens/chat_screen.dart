import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final List<String>? members; // Thêm danh sách thành viên cho chat nhóm

  const ChatScreen({super.key, required this.userName, this.members});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'You', 'message': 'Hi! How are you?', 'type': 'text'},
    {
      'sender': 'Other',
      'message': 'Hey! I’m good, thanks for asking.',
      'type': 'text',
    },
    {'sender': 'You', 'message': 'Great to hear that!', 'type': 'text'},
    {
      'sender': 'Other',
      'message': 'What about you? How’s your day going?',
      'type': 'text',
    },
    {
      'sender': 'You',
      'message': 'Shared a file: document.pdf',
      'type': 'file',
      'fileUrl': 'https://example.com/document.pdf',
    },
  ];

  bool _isOnline = true;

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'You',
          'message': _messageController.text,
          'type': 'text',
        });
        _messageController.clear();

        // Simulate incoming message
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add({
              'sender': 'Other',
              'message': 'I got your message! 😊',
              'type': 'text',
            });
          });
        });
      });
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
                  setState(() {
                    _messages.add({
                      'sender': 'You',
                      'message': 'Shared a file: sample.pdf',
                      'type': 'file',
                      'fileUrl': 'https://example.com/sample.pdf',
                    });
                  });
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
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              widget.userName,
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
                                            _isOnline
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
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
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
                                // Mở file (giả lập)
                                print('Opening file: ${message['fileUrl']}');
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
