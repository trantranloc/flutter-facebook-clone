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

  void _showSettingsMenu(BuildContext context, MessageProvider provider) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('New message'),
                  onTap: () {
                    Navigator.pop(context);
                    //   Implement new message
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
                    //   Implement mark all as read
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    //   Implement camera
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    //   Implement settings
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, MessageProvider provider) {
    final TextEditingController groupNameController = TextEditingController();
    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Group'),
            content: StatefulBuilder(
              builder:
                  (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter group name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select members:'),
                      SizedBox(
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
                  if (groupNameController.text.isNotEmpty &&
                      selectedMembers.isNotEmpty) {
                    provider.createGroup(
                      groupNameController.text,
                      selectedMembers,
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a group name and select at least one member',
                        ),
                      ),
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
                  onPressed: () => _showSettingsMenu(context, provider),
                ),
              ],
            ),
            body: Column(
              children: [
                // Messenger-style Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Messenger',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
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
                  child:
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                            children: [
                              // Horizontal Friends Section
                              Container(
                                height: 90,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children:
                                      provider.friendsList.take(7).map((
                                        friend,
                                      ) {
                                        return FriendAvatar(
                                          name: friend['name'],
                                          image: friend['avatarUrl'],
                                          isActive: friend['isActive'],
                                          onTap: () {
                                            context.go(
                                              friend['isGroup'] == true
                                                  ? '/message/group/${friend['uid']}'
                                                  : '/message/chat/${friend['uid']}',
                                            );
                                          },
                                        );
                                      }).toList(),
                                ),
                              ),
                              const Divider(),
                              // Messages Section
                              ...provider.friendsList.asMap().entries.map((
                                entry,
                              ) {
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
                                    context.go(
                                      friend['isGroup'] == true
                                          ? '/message/group/${friend['uid']}'
                                          : '/message/chat/${friend['uid']}',
                                    );
                                  },
                                  onMoreTap: () {
                                    _showChatOptions(
                                      context,
                                      provider,
                                      friend['uid'],
                                      index,
                                      friend['isGroup'] ?? false,
                                    );
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

  void _showChatOptions(
    BuildContext context,
    MessageProvider provider,
    String friendId,
    int index,
    bool isGroup,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: Text(
                    provider.friendsList[index]['isPinned'] ?? false
                        ? 'Unpin chat'
                        : 'Pin chat',
                  ),
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
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Chat'),
                            content: const Text(
                              'Are you sure you want to delete this chat?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteChat(
                                    friendId,
                                    isGroup: isGroup,
                                  );
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
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
                      context.go('/message/group/$friendId/details');
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
                      image.isNotEmpty
                          ? NetworkImage(image)
                          : const AssetImage('assets/user.jpg')
                              as ImageProvider,
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
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage:
                avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/group.jpg') as ImageProvider,
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
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isPinned)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.push_pin, size: 16, color: Colors.grey),
            ),
          if (isGroup)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.group, size: 16, color: Colors.grey),
            ),
        ],
      ),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.grey),
        onPressed: onMoreTap,
      ),
      onTap: onTap,
    );
  }
}
//danh sách người chat