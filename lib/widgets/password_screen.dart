import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Lấy dữ liệu từ các màn hình trước
        final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final email = args?['email'] as String?;
        final firstName = args?['firstName'] as String?;
        final lastName = args?['lastName'] as String?;
        final gender = args?['gender'] as String?;

        if (email == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Không tìm thấy email')));
          return;
        }

        // Tạo tên đầy đủ từ firstName và lastName
        final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();

        // Hiển thị loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        // Gọi AuthService để đăng ký
        final authService = AuthService();
        final user = await authService.signUp(email, _passwordController.text);

        // Ẩn loading
        Navigator.pop(context);

        if (user != null) {
          // Tạo UserModel
          final userModel = UserModel(
            uid: user.uid,
            name: fullName.isNotEmpty ? fullName : 'Unknown',
            email: email,
            avatarUrl: '',
            gender: gender ?? 'Unknown',
            createdAt: DateTime.now(),
          );

          // In UserModel để kiểm tra
          print('UserModel: ${userModel.toMap()}');
          await authService.saveUser(userModel);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
          context.go('/home');
        }
      } catch (e) {
        // Ẩn loading nếu có lỗi
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng ký: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo mật khẩu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[800],
                  ),
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
