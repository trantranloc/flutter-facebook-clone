import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/message_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageProvider(),
      child: Consumer<MessageProvider>(
        builder: (context, provider, child) {
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
                    showSearchDialog(context, provider);
                  },
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // Horizontal Friends Section
                      Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: provider.friendsList.take(7).map((friend) {
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
                      ...provider.friendsList.map((friend) {
                        return MessageTile(
                          name: friend['name'],
                          message: friend['lastMessage'],
                          avatarUrl: friend['avatarUrl'],
                          isActive: friend['isActive'],
                          onTap: () {
                            context.go('/message/chat/${friend['uid']}');
                          },
                        );
                      }),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void showSearchDialog(BuildContext context, MessageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Friends'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter friend\'s name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            provider.searchFriends(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              provider.clearSearch();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
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
                  backgroundImage: image.isNotEmpty
                      ? NetworkImage(image)
                      : const AssetImage('assets/user.jpg') as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading image: $exception');
                  },
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
            SizedBox(
              width: 60,
              child: Text(
                name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
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
  final String avatarUrl;
  final bool isActive;
  final VoidCallback onTap;

  const MessageTile({
    super.key,
    required this.name,
    required this.message,
    required this.avatarUrl,
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
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/user.jpg') as ImageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
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
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}