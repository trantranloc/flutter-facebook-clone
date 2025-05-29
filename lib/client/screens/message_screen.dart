import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/message_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // Thêm import cho base64Decode

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

  void _showSettingsMenu(BuildContext context, MessageProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('New message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement new message
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('New group'),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_unread),
              title: const Text('Mark all as read'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mark all as read
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, MessageProvider provider) {
    final TextEditingController _groupNameController = TextEditingController();
    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select members:'),
              Container(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: provider.friendsList.length,
                  itemBuilder: (context, index) {
                    final friend = provider.friendsList[index];
                    return CheckboxListTile(
                      title: Text(friend['name']),
                      value: selectedMembers.contains(friend['uid']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedMembers.add(friend['uid']);
                          } else {
                            selectedMembers.remove(friend['uid']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_groupNameController.text.isNotEmpty && selectedMembers.isNotEmpty) {
                provider.createGroup(_groupNameController.text, selectedMembers);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name and select at least one member')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageProvider(),
      child: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              title: Text(
                'Messages',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => _showSettingsMenu(context, provider),
                ),
              ],
            ),
            body: Column(
              children: [
                // Messenger-style Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Messenger',
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      provider.searchFriends(value);
                    },
                  ),
                ),
                Expanded(
                  child: provider.isLoading
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
                                    isGroup: friend['isGroup'] ?? false, // Thêm isGroup
                                    onTap: () {
                                      context.go(friend['isGroup'] == true
                                          ? '/message/group/${friend['uid']}'
                                          : '/message/chat/${friend['uid']}');
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const Divider(),
                            // Messages Section
                            ...provider.friendsList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final friend = entry.value;
                              return MessageTile(
                                name: friend['name'],
                                message: friend['lastMessage'],
                                avatarUrl: friend['avatarUrl'],
                                isActive: friend['isActive'],
                                isPinned: friend['isPinned'] ?? false,
                                isGroup: friend['isGroup'] ?? false,
                                onTap: () {
                                  context.go(friend['isGroup'] == true
                                      ? '/message/group/${friend['uid']}'
                                      : '/message/chat/${friend['uid']}');
                                },
                                onMoreTap: () {
                                  _showChatOptions(context, provider, friend['uid'], index, friend['isGroup'] ?? false);
                                },
                              );
                            }),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChatOptions(BuildContext context, MessageProvider provider, String friendId, int index, bool isGroup) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(provider.friendsList[index]['isPinned'] ?? false ? 'Unpin chat' : 'Pin chat'),
              onTap: () {
                provider.togglePinChat(friendId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete chat'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Chat'),
                    content: const Text('Are you sure you want to delete this chat?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteChat(friendId, isGroup: isGroup);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (isGroup)
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('View group details'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/message/group/${friendId}/details');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class FriendAvatar extends StatelessWidget {
  final String name;
  final String image;
  final bool isActive;
  final bool isGroup; // Thêm isGroup
  final VoidCallback onTap;

  const FriendAvatar({
    super.key,
    required this.name,
    required this.image,
    required this.isActive,
    required this.isGroup, // Thêm isGroup
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    try {
      if (image.isNotEmpty) {
        if (isGroup && !image.startsWith('assets/')) {
          // Nhóm với avatar base64
          imageProvider = MemoryImage(base64Decode(image));
        } else if (image.startsWith('assets/')) {
          // Tài nguyên mặc định
          imageProvider = AssetImage(image);
        } else {
          // Bạn bè với URL mạng
          imageProvider = NetworkImage(image);
        }
      } else {
        imageProvider = isGroup
            ? const AssetImage('assets/group.jpg')
            : const AssetImage('assets/user.jpg');
      }
    } catch (e) {
      // Dự phòng nếu base64 không hợp lệ
      imageProvider = isGroup
          ? const AssetImage('assets/group.jpg')
          : const AssetImage('assets/user.jpg');
      print('Error loading image: $e');
    }

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
                  backgroundImage: imageProvider,
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
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
  final bool isPinned;
  final bool isGroup;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const MessageTile({
    super.key,
    required this.name,
    required this.message,
    required this.avatarUrl,
    required this.isActive,
    required this.isPinned,
    required this.isGroup,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    try {
      if (avatarUrl.isNotEmpty) {
        if (isGroup && !avatarUrl.startsWith('assets/')) {
          // Nhóm với avatar base64
          imageProvider = MemoryImage(base64Decode(avatarUrl));
        } else if (avatarUrl.startsWith('assets/')) {
          // Tài nguyên mặc định
          imageProvider = AssetImage(avatarUrl);
        } else {
          // Bạn bè với URL mạng
          imageProvider = NetworkImage(avatarUrl);
        }
      } else {
        imageProvider = isGroup
            ? const AssetImage('assets/group.jpg')
            : const AssetImage('assets/user.jpg');
      }
    } catch (e) {
      // Dự phòng nếu base64 không hợp lệ
      imageProvider = isGroup
          ? const AssetImage('assets/group.jpg')
          : const AssetImage('assets/user.jpg');
      print('Error loading image: $e');
    }

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: imageProvider,
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
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (isPinned)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.push_pin,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (isGroup)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.group,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: onMoreTap,
      ),
      onTap: onTap,
    );
  }
}
//giao diện chat