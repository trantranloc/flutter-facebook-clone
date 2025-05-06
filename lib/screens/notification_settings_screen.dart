import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _storyNotifications = true;
  bool _eventNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Likes'),
            subtitle: const Text(
              'Receive notifications for likes on your posts',
            ),
            value: _likeNotifications,
            onChanged: (value) {
              setState(() {
                _likeNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Comments'),
            subtitle: const Text(
              'Receive notifications for comments on your posts',
            ),
            value: _commentNotifications,
            onChanged: (value) {
              setState(() {
                _commentNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Stories'),
            subtitle: const Text(
              'Receive notifications for story interactions',
            ),
            value: _storyNotifications,
            onChanged: (value) {
              setState(() {
                _storyNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Events & Birthdays'),
            subtitle: const Text('Receive reminders for events and birthdays'),
            value: _eventNotifications,
            onChanged: (value) {
              setState(() {
                _eventNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
