import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/theme_provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AdminChoiceScreen extends StatelessWidget {
  const AdminChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [
                      const Color(0xFF121212), // Dark Background
                      const Color(0xFF1E1E1E),
                    ]
                    : [
                      const Color(0xFFFFF3E0), // Peach
                      const Color(0xFFE1F5FE), // Light Blue
                    ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chào mừng Admin',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Đảm bảo sử dụng adminRouter
                      userProvider.setAdminRouter(true);
                      // Điều hướng đến trang quản lý
                      context.go('/admin');
                    },
                    child: const Text(
                      'Đến Trang Quản Lý',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      // Chuyển sang userRouter
                      userProvider.setAdminRouter(false);
                      // Delay để đảm bảo state đã được cập nhật
                      Future.microtask(() {
                        // Sử dụng GoRouter sau khi đã chuyển sang userRouter
                        context.go('/');
                      });
                    },
                    child: Text(
                      'Đến Trang Người Dùng',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
