import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/chat_service.dart';
import 'package:go_router/go_router.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // Dữ liệu bạn bè từ Firestore
  List<Map<String, dynamic>> _friendsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  // Lấy danh sách bạn bè từ ChatService
  Future<void> _fetchFriends() async {
    final chatService = ChatService();
    final friends = await chatService.getFriendsWithLastMessage();
    if (mounted) {
      // Kiểm tra xem widget còn mounted trước khi gọi setState
      setState(() {
        _friendsList = friends;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Settings action
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Search action
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  // Horizontal Friends Section
                  Container(
                    height: 90,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          _friendsList.take(7).map((friend) {
                            return FriendAvatar(
                              name: friend['name'],
                              image: friend['avatarUrl'],
                              isActive: friend['isActive'],
                              onTap: () {
                                context.go('/message/chat/${friend['uid']}');
                              },
                            );
                          }).toList(),
                    ),
                  ),
                  const Divider(),
                  // Messages Section
                  ..._friendsList.map((friend) {
                    return MessageTile(
                      name: friend['name'],
                      message: friend['lastMessage'],
                      isActive: friend['isActive'],
                      onTap: () {
                        context.go('/message/chat/${friend['uid']}');
                      },
                    );
                  }),
                ],
              ),
    );
  }
}

class FriendAvatar extends StatelessWidget {
  final String name;
  final String image;
  final bool isActive;
  final VoidCallback onTap;

  const FriendAvatar({
    super.key,
    required this.name,
    required this.image,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      image.startsWith('http')
                          ? NetworkImage(image)
                          : AssetImage(image) as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading image: $exception');
                  },
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String name;
  final String message;
  final bool isActive;
  final VoidCallback onTap;

  const MessageTile({
    super.key,
    required this.name,
    required this.message,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('assets/user.jpg'),
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      onTap: onTap,
    );
  }
}
