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
    // Validate input
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ email và mật khẩu.';
      });
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        errorMessage =
            'Định dạng email không hợp lệ. Vui lòng nhập email đúng định dạng.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Xóa dữ liệu người dùng trước khi đăng nhập
    await context.read<UserProvider>().clearUser();

    try {
      // Đăng nhập bằng Firebase Authentication
      User? user = await _authService.signIn(email, password);
      if (user == null) {
        setState(() {
          errorMessage =
              'Đăng nhập thất bại: Không thể xác thực tài khoản. Vui lòng thử lại.';
          isLoading = false;
        });
        return;
      }

      // Kiểm tra trạng thái ban và block từ Firestore
      Map<String, dynamic> banStatus = await _authService.getUserBanStatus(
        user.uid,
      );

      if (banStatus['isBanned'] == true) {
        await _authService.signOut(); // Đăng xuất ngay lập tức
        String banMessage = _authService.formatBanMessage(
          banStatus['bannedReason'] ?? 'Không có lý do cụ thể',
          banStatus['bannedUntil'],
        );

        setState(() {
          errorMessage = banMessage;
          isLoading = false;
        });
        return;
      }

      if (banStatus['isBlocked'] == true) {
        await _authService.signOut(); // Đăng xuất ngay lập tức
        setState(() {
          errorMessage =
              'Tài khoản của bạn đã bị khóa vĩnh viễn.\n\nVui lòng liên hệ quản trị viên để biết thêm chi tiết.';
          isLoading = false;
        });
        return;
      }

      // Tải dữ liệu người dùng vào UserProvider
      await context.read<UserProvider>().loadUserData(user.uid, UserService());

      // Double check từ UserProvider
      if (context.read<UserProvider>().isBlocked) {
        await _authService.signOut(); // Đăng xuất ngay lập tức
        setState(() {
          errorMessage =
              'Tài khoản của bạn đã bị khóa.\n\nVui lòng liên hệ quản trị viên.';
          isLoading = false;
        });
        return;
      }

      // Kiểm tra trạng thái admin
      await context.read<UserProvider>().checkAdminStatus();
      bool isAdmin = context.read<UserProvider>().isAdmin;
      await Future.delayed(Duration(milliseconds: 100));
      // Chuyển hướng dựa trên trạng thái admin
      if (isAdmin) {
        context.go('/admin/choice');
        print('Đăng nhập thành công với tư cách admin: $isAdmin');
      } else {
        context.go('/');
        print('Đăng nhập thành công với tư cách người dùng thường');
      }
    } on FirebaseAuthException catch (e) {
      String message = _handleFirebaseAuthError(e);
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    } catch (e) {
      String message = e.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.\n\nVui lòng kiểm tra lại email hoặc tạo tài khoản mới.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.\n\nVui lòng thử lại hoặc sử dụng chức năng "Quên mật khẩu?".';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.\n\nVui lòng nhập email đúng định dạng (ví dụ: example@gmail.com).';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa bởi quản trị viên.\n\nVui lòng liên hệ hỗ trợ.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử đăng nhập.\n\nVui lòng đợi một lúc trước khi thử lại.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng.\n\nVui lòng kiểm tra kết nối internet và thử lại.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.\n\nVui lòng kiểm tra lại email và mật khẩu.';
      default:
        return 'Đăng nhập thất bại: ${e.message ?? "Lỗi không xác định"}';
    }
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          content: Text(message, style: const TextStyle(height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
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
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signIn(),
                      decoration: const InputDecoration(
                        hintText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withOpacity(0.1),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _signIn,
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang đăng nhập...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
