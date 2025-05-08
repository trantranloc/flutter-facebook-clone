import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/screens/group_screen.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _auth = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Load user data after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && userProvider.userModel == null) {
        userProvider.loadUserData(currentUser.uid, _userService);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userModel = userProvider.userModel;
        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body:
              userProvider.isLoading && userModel == null
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
                                  if (userModel != null) {
                                    context.go(
                                      '/profile',
                                      extra: userModel.uid,
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey[300],
                                      child:
                                          userModel?.avatarUrl.isNotEmpty ??
                                                  false
                                              ? ClipOval(
                                                child: Image.network(
                                                  userModel!.avatarUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return const CircularProgressIndicator();
                                                  },
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userModel?.name ?? 'Đang tải...',
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
                                    ),
                                  ],
                                ),
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
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    key: 'friends',
                                    icon: Icons.group,
                                    title: 'Bạn bè',
                                    onTap: () => context.go('/list-friend'),
                                  ),
                                  _buildMenuItem(
                                    key: 'marketplace',
                                    icon: Icons.store,
                                    title: 'Marketplace',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'memories',
                                    icon: Icons.history,
                                    title: 'Ký ức',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'events',
                                    icon: Icons.event,
                                    title: 'Sự kiện',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'groups',
                                    icon: Icons.group_work,
                                    title: 'Nhóm',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'settings',
                                    icon: Icons.settings,
                                    title: 'Cài đặt & quyền riêng tư',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'help',
                                    icon: Icons.help,
                                    title: 'Trợ giúp & hỗ trợ',
                                    onTap:
                                        () => ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tính năng đang phát triển',
                                            ),
                                          ),
                                        ),
                                  ),
                                  _buildMenuItem(
                                    key: 'logout',
                                    icon: Icons.logout,
                                    title: 'Đăng xuất',
                                    onTap: () async {
                                      await _auth.signOut();
                                      await userProvider.clearUser();
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
      },
    );
  }

  Widget _buildMenuItem({
    required String key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: ValueKey(key), // Thêm key duy nhất
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
