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
      rethrow; // ném lỗi ra ngoài để UI hiển thị được lỗi
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

  /// Theo dõi trạng thái đăng nhập của người dùng
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
