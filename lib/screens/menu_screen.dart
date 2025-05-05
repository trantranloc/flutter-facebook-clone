// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Profile Section
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: const Text(
              'Your Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('See your profile'),
            onTap: () {},
          ),
          const Divider(),
          // Menu Items
          ListTile(
            leading: const Icon(Icons.group, color: Color(0xFF1877F2)),
            title: const Text('Groups'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.event, color: Color(0xFF1877F2)),
            title: const Text('Events'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF1877F2)),
            title: const Text('Settings & Privacy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF1877F2)),
            title: const Text('Log Out'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
