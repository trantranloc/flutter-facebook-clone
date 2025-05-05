// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Sample Notification
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: const Text('Jane Smith liked your post'),
            subtitle: const Text('2 hours ago'),
            trailing: const Icon(Icons.thumb_up, color: Color(0xFF1877F2)),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: const Text('John Doe commented on your photo'),
            subtitle: const Text('Yesterday'),
            trailing: const Icon(Icons.comment, color: Color(0xFF1877F2)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
