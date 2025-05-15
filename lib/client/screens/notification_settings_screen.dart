import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Tải cài đặt từ Firestore
  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _likeNotifications = data['notificationSettings']?['likes'] ?? true;
          _commentNotifications =
              data['notificationSettings']?['comments'] ?? true;
          _storyNotifications =
              data['notificationSettings']?['stories'] ?? true;
          _eventNotifications = data['notificationSettings']?['events'] ?? true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải cài đặt: $e')));
    }
  }

  // Lưu cài đặt vào Firestore
  Future<void> _saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notificationSettings': {
          'likes': _likeNotifications,
          'comments': _commentNotifications,
          'stories': _storyNotifications,
          'events': _eventNotifications,
        },
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt thông báo')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu cài đặt: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: const Text('Lượt thích'),
                subtitle: const Text(
                  'Nhận thông báo khi có lượt thích bài viết',
                ),
                value: _likeNotifications,
                onChanged: (value) {
                  setState(() {
                    _likeNotifications = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Bình luận'),
                subtitle: const Text(
                  'Nhận thông báo khi có bình luận bài viết',
                ),
                value: _commentNotifications,
                onChanged: (value) {
                  setState(() {
                    _commentNotifications = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Tin'),
                subtitle: const Text(
                  'Nhận thông báo khi có tương tác với tin của bạn',
                ),
                value: _storyNotifications,
                onChanged: (value) {
                  setState(() {
                    _storyNotifications = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Sự kiện & Sinh nhật'),
                subtitle: const Text(
                  'Nhận thông báo nhắc nhở sự kiện và sinh nhật',
                ),
                value: _eventNotifications,
                onChanged: (value) {
                  setState(() {
                    _eventNotifications = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Lưu cài đặt',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
