import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/theme_provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:flutter_facebook_clone/widgets/personal_info_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  void _signIn() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Xóa dữ liệu người dùng trước khi đăng nhập
    await context.read<UserProvider>().clearUser();

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      // Đăng nhập bằng Firebase Authentication
      User? user = await _authService.signIn(email, password);
      if (user == null) {
        setState(() {
          errorMessage = 'Đăng nhập thất bại: Không tìm thấy người dùng';
          isLoading = false;
        });
        return;
      }

      // Kiểm tra trạng thái khóa từ Firestore
      bool isBlocked = await _authService.isUserBlocked(user.uid);
      if (isBlocked) {
        await _authService.signOut(); // Đăng xuất ngay lập tức
        setState(() {
          errorMessage =
              'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
          isLoading = false;
        });
        return;
      }

      // Tải dữ liệu người dùng vào UserProvider
      await context.read<UserProvider>().loadUserData(user.uid, UserService());
      if (context.read<UserProvider>().isBlocked) {
        await _authService.signOut(); // Đăng xuất ngay lập tức
        setState(() {
          errorMessage =
              'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
          isLoading = false;
        });
        return;
      }

      // Kiểm tra trạng thái admin
      await context.read<UserProvider>().checkAdminStatus();
      bool isAdmin = context.read<UserProvider>().isAdmin;

      // Chuyển hướng dựa trên trạng thái admin
      if (isAdmin) {
        context.go('/admin/choice');
        print('Đăng nhập thành công với tư cách admin: $isAdmin');
      } else {
        context.go('/');
        print('Đăng nhập thành công với tư cách người dùng thường');

      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          message = 'Đăng nhập thất bại: ${e.message}';
      }
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Đăng nhập thất bại: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng ThemeProvider từ context
    final themeProvider = Provider.of<ThemeProvider>(context);
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
                      const Color(0xFFE1BEE7), // Peach
                      const Color(0xFFE1F5FE), // Light Blue
                    ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logos.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Số điện thoại hoặc email',
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Mật khẩu'),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 15),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _signIn,
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const Divider(height: 40, thickness: 1),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: OutlinedButton(
                        onPressed: () {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const PersonalInfoScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi điều hướng: $e')),
                            );
                          }
                        },
                        child: Text(
                          'Tạo tài khoản mới',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
