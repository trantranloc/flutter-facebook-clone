import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/User.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _auth = AuthService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userModel = await _auth.getUser(currentUser.uid);
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _isLoading = false;
          });
        }
        if (userModel == null) {
          print('Không tìm thấy thông tin người dùng');
        }
      } else {
        print('Người dùng chưa đăng nhập');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Trì hoãn chuyển hướng đến sau khi build hoàn tất
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  // Profile Section
                  ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    title: Text(
                      _userModel?.name ?? 'Your Name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('See your profile'),
                    onTap: () {
                      if (_userModel != null) {
                        context.go('/profile', extra: _userModel!.uid);
                      }
                    },
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
                    leading: const Icon(
                      Icons.settings,
                      color: Color(0xFF1877F2),
                    ),
                    title: const Text('Settings & Privacy'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFF1877F2)),
                    title: const Text('Log Out'),
                    onTap: () async {
                      await _auth.signOut();
                      if (mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
    );
  }
}
