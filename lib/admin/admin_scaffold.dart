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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Column(
            children: [
              DrawerHeader(
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
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Tổng quan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/overview');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Quản lý Người dùng'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/user-management');
                },
              ),
              ListTile(
                leading: const Icon(Icons.post_add),
                title: const Text('Quản lý Bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/post-management');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Chuyển sang Người dùng'),
                onTap: () {
                  userProvider.setAdminRouter(false);
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  try {
                    await AuthService().signOut();
                    Navigator.pop(context);
                    context.go('/login');
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi đăng xuất: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: body,
    );
  }
}
