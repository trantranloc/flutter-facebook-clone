import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/theme_provider.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  const AdminScaffold({super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          appBar: _buildAppBar(),
          drawer: _buildDrawer(context, isDarkMode, userProvider),
          body: body,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(title),
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    bool isDarkMode,
    UserProvider userProvider,
  ) {
    return Drawer(
      child: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(isDarkMode),
            ..._buildMenuItems(context, userProvider),
            const Spacer(),
            _buildLogoutItem(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDarkMode) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.blue,
      ),
      child: const Center(
        child: Text(
          'Quản Lý',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    UserProvider userProvider,
  ) {
    final menuItems = [
      _MenuItem(
        icon: Icons.dashboard,
        title: 'Tổng quan',
        route: '/admin/overview',
      ),
      _MenuItem(
        icon: Icons.people,
        title: 'Quản lý Người dùng',
        route: '/admin/user-management',
      ),
      _MenuItem(
        icon: Icons.post_add,
        title: 'Quản lý Bài viết',
        route: '/admin/post-management',
      ),
    ];

    return [
      ...menuItems.map((item) => _buildMenuListTile(context, item)),
      _buildSwitchToUserTile(context, userProvider),
    ];
  }

  Widget _buildMenuListTile(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      onTap: () => _navigateToRoute(context, item.route),
    );
  }

  Widget _buildSwitchToUserTile(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Chuyển sang Người dùng'),
      onTap: () {
        userProvider.setAdminRouter(false);
        _navigateToRoute(context, '/');
      },
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Đăng xuất'),
      onTap: () => _handleLogout(context),
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pop(context);
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorSnackBar(context, 'Lỗi đăng xuất: $e');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String route;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}
