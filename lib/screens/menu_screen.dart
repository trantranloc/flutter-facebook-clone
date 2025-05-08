import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/screens/group_screen.dart';
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
  bool _hasLoaded = false; // Biến để theo dõi trạng thái tải

  @override
  void initState() {
    super.initState();
    if (!_hasLoaded) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_hasLoaded) return; // Thoát nếu dữ liệu đã được tải

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userModel = await _auth.getUser(currentUser.uid);
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _isLoading = false;
            _hasLoaded = true; // Đánh dấu dữ liệu đã tải
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
            _hasLoaded = true; // Đánh dấu đã xử lý
          });
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
          _hasLoaded = true; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: () {
                              if (_userModel != null) {
                                context.go('/profile', extra: _userModel!.uid);
                              }
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[300],
                                  child:
                                      _userModel?.avatarUrl.isNotEmpty ?? false
                                          ? ClipOval(
                                            child: Image.network(
                                              _userModel!.avatarUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.person,
                                                    size: 30,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userModel?.name ?? 'Tên của bạn',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Xem trang cá nhân của bạn',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                        // Menu Items
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.group,
                                title: 'Bạn bè',
                                onTap: () => context.go('/friends'),
                              ),
                              _buildMenuItem(
                                icon: Icons.store,
                                title: 'Marketplace',
                                onTap: () {},
                              ),
                              _buildMenuItem(
                                icon: Icons.history,
                                title: 'Ký ức',
                                onTap: () {},
                              ),
                              _buildMenuItem(
                                icon: Icons.event,
                                title: 'Sự kiện',
                                onTap: () {},
                              ),
                              _buildMenuItem(
                                icon: Icons.group_work,
                                title: 'Nhóm',
                                onTap: () {
                                  Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GroupScreen(),
                              ),
                            );
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.settings,
                                title: 'Cài đặt & quyền riêng tư',
                                onTap: () {},
                              ),
                              _buildMenuItem(
                                icon: Icons.help,
                                title: 'Trợ giúp & hỗ trợ',
                                onTap: () {},
                              ),
                              _buildMenuItem(
                                icon: Icons.logout,
                                title: 'Đăng xuất',
                                onTap: () async {
                                  await _auth.signOut();
                                  if (mounted) {
                                    context.go('/login');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1877F2), size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
