import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Khởi tạo FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Đăng nhập bằng email và mật khẩu
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      print('Lỗi gửi email đặt lại mật khẩu: $e');
      rethrow;
    }
  }

  /// Cập nhật mật khẩu mới
  Future<void> updatePassword(
    String email,
    String verificationCode,
    String newPassword,
  ) async {
    try {
      // Đăng nhập tạm thời với mã xác thực
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: verificationCode,
      );

      if (userCredential.user == null) {
        throw Exception('Không thể xác thực tài khoản');
      }

      // Cập nhật mật khẩu mới
      await userCredential.user!.updatePassword(newPassword);

      // Đăng xuất để người dùng đăng nhập lại với mật khẩu mới
      await _auth.signOut();
    } catch (e) {
      print('Lỗi cập nhật mật khẩu: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('Không tìm thấy tài khoản với email này');
          case 'wrong-password':
            throw Exception('Mã xác thực không chính xác');
          case 'invalid-email':
            throw Exception('Email không hợp lệ');
          case 'user-disabled':
            throw Exception('Tài khoản đã bị vô hiệu hóa');
          default:
            throw Exception('Không thể cập nhật mật khẩu: ${e.message}');
        }
      }
      rethrow;
    }
  }

  /// Theo dõi trạng thái đăng nhập của người dùng
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
