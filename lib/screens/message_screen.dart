import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // Giả lập trạng thái hoạt động cho từng người
  final Map<String, bool> _statusMap = {
    'Jorge': true,
    'Claire': false,
    'Darrell': true,
    'Aubrey': false,
    'Dustin': true,
    'Albert Flores': true,
    'Bessie Cooper': false,
    'Esther Howard': true,
    'Kathryn Murphy': false,
    'Darrell Steward': true,
    'Savannah Nguyen': false,
    'Jerome Bell': true,
    'Wade Warren': false,
    'Robert Fox': true,
  };

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
      body: ListView(
        children: [
          // Horizontal Friends Section
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FriendAvatar(
                  name: 'Jorge',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Jorge']!,
                  onTap: () {
                    context.go('/message/chat/Jorge');
                  },
                ),
                FriendAvatar(
                  name: 'Claire',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Claire']!,
                  onTap: () {
                    context.go('/message/chat/Claire');
                  },
                  
                ),
                FriendAvatar(
                  name: 'Darrell',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Darrell']!,
                  onTap: () {
                    context.go('/message/chat/Darrell');
                  },
                ),
                FriendAvatar(
                  name: 'Aubrey',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Aubrey']!,
                  onTap: () {
                    context.go('/message/chat/Aubrey');
                  },
                ),
                FriendAvatar(
                  name: 'Dustin',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Dustin']!,
                  onTap: () {
                    context.go('/message/chat/Dustin');
                  },
                ),
                FriendAvatar(
                  name: 'Dustin',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Dustin']!,
                  onTap: () {
                    context.go('/message/chat/Dustin');
                  },
                ),
                FriendAvatar(
                  name: 'Dustin',
                  image: 'assets/ronaldo.jpg',
                  isActive: _statusMap['Dustin']!,
                  onTap: () {
                    context.go('/message/chat/Dustin');
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Messages Section
          MessageTile(
            name: 'Albert Flores',
            message: 'Hey! Whats up!',
            isActive: _statusMap['Albert Flores']!,
            onTap: () {
              context.go('/message/chat/Albert Flores');
            },
          ),
          MessageTile(
            name: 'Bessie Cooper',
            message: 'tastes amazing!',
            isActive: _statusMap['Bessie Cooper']!,
            onTap: () {
              context.go('/message/chat/Bessie Cooper');
            },
          ),
          MessageTile(
            name: 'Esther Howard',
            message: 'when will it be ready?',
            isActive: _statusMap['Esther Howard']!,
            onTap: () {
              context.go('/message/chat/Esther Howard');
            },
          ),
          MessageTile(
            name: 'Kathryn Murphy',
            message: 'Lo intento gracias',
            isActive: _statusMap['Kathryn Murphy']!,
            onTap: () {
              context.go('/message/chat/Kathryn Murphy');
            },
          ),
          MessageTile(
            name: 'Darrell Steward',
            message: 'Ready to explore new places ✈️',
            isActive: _statusMap['Darrell Steward']!,
            onTap: () {
              context.go('/message/chat/Darrell Steward');
            },
          ),
          MessageTile(
            name: 'Savannah Nguyen',
            message: 'Change/cancel appointment',
            isActive: _statusMap['Savannah Nguyen']!,
            onTap: () {
              context.go('/message/chat/Savannah Nguyen');
            },
          ),
          MessageTile(
            name: 'Jerome Bell',
            message: 'Administrative question',
            isActive: _statusMap['Jerome Bell']!,
            onTap: () {
              context.go('/message/chat/Jerome Bell');
            },
          ),
          MessageTile(
            name: 'Wade Warren',
            message: 'Need a hug 🥰',
            isActive: _statusMap['Wade Warren']!,
            onTap: () {
              context.go('/message/chat/Wade Warren');
            },
          ),
          MessageTile(
            name: 'Robert Fox',
            message: 'Yoga is the key to finding inner peace 🧘',
            isActive: _statusMap['Robert Fox']!,
            onTap: () {
              context.go('/message/chat/Robert Fox');
            },
          ),
        ],
      ),
    );
  }
}

class FriendAvatar extends StatelessWidget {
  final String name;
  final String image;
  final bool isActive; // Thêm trạng thái hoạt động
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
                  backgroundImage: AssetImage(image),
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
  final bool isActive; // Thêm trạng thái hoạt động
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
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(message),
      onTap: onTap,
    );
  }
}