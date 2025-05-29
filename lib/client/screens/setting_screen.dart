import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Hiển thị'),
          _buildThemeSettings(context),
          const Divider(),
          _buildSectionHeader('Tài khoản'),
          _buildAccountSettings(context),
          const Divider(),
          _buildSectionHeader('Trợ giúp'),
          _buildHelpSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1877F2),
        ),
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Chế độ tối'),
          subtitle: const Text('Chuyển đổi giữa giao diện sáng và tối'),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: const Color(0xFF1877F2),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.format_paint),
          title: const Text('Màu sắc ứng dụng'),
          subtitle: const Text('Tùy chỉnh màu sắc giao diện'),
          onTap: () {
            // Show color customization dialog or navigate to color settings screen
            _showColorCustomizationDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Thông tin cá nhân'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Bảo mật và đăng nhập'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHelpSettings(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Trung tâm trợ giúp'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Báo cáo vấn đề'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Thông tin phiên bản'),
          subtitle: const Text('Version 1.0.0'),
          onTap: () {},
        ),
      ],
    );
  }

  void _showColorCustomizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tùy chỉnh màu sắc'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tính năng tùy chỉnh màu sắc nâng cao sẽ được triển khai trong phiên bản tới.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Hiện tại bạn có thể chuyển đổi giữa chế độ sáng và tối.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
