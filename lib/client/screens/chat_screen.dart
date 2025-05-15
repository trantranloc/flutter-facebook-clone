import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/chat_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _otherUserData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOtherUserData();
  }

  // Fetch other user's data
  Future<void> _fetchOtherUserData() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (userDoc.exists && mounted) {
      setState(() {
        _otherUserData = userDoc.data();
      });
    }
  }

  // Send text message
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.userId,
        _messageController.text.trim(),
        'text',
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  // Send image
  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(File(image.path));
      final imageUrl = await storageRef.getDownloadURL();

      await _chatService.sendMessage(
        widget.userId,
        'Sent an image',
        'image',
        fileUrl: imageUrl,
      );
      _scrollToBottom();
    }
  }

  // Mock voice call
  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initiating voice call... (Mocked)')),
    );
    // Implement actual voice call with Agora/Twilio here
  }

  // Mock video call
  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initiating video call... (Mocked)')),
    );
    // Implement actual video call with Agora/Twilio here
  }

  // Show image gallery
  void _showImageGallery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getMessages(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading images'));
              }
              final images = snapshot.data
                      ?.where((msg) => msg['type'] == 'image')
                      .toList() ??
                  [];
              if (images.isEmpty) {
                return const Center(child: Text('No images found'));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index]['fileUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Share file
  void _shareFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter file URL (mock)',
              ),
              onChanged: (value) {
                // Mock file URL input
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
              _scrollToBottom();
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  // Scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: _startVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            onPressed: _startVideoCall,
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
                  child: Text('View Image Gallery'),
                ),
              ];
            },
          ),
        ],
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
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender'] == 'You';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                        child: message['type'] == 'image'
                            ? Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    message['fileUrl'],
                                    width: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text('Error loading image'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message['message']!,
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                                ],
                              )
                            : message['type'] == 'file'
                                ? InkWell(
                                    onTap: () {
                                      print('Opening file: ${message['fileUrl']}');
                                    },
                                    child: Column(
                                      crossAxisAlignment: isMe
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
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
    super.dispose();
  }
}