import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Khởi tạo FirebaseAuth và FirebaseFirestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      final isAdmin = data['isAdmin'];

      print("Giá trị isAdmin trong Firestore: $isAdmin");

      return isAdmin == true;
    } catch (e) {
      print('Lỗi kiểm tra admin: $e');
      return false;
    }
  }

  Future<bool> isUserBlocked(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!userDoc.exists) return false;
      final data = userDoc.data() as Map<String, dynamic>;
      return data['isBlocked'] == true;
    } catch (e) {
      print('Lỗi kiểm tra tài khoản bị khóa: $e');
      return false;
    }
  }

  /// Đăng nhập bằng email và mật khẩu
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng nhập: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
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
      // Lưu thông tin người dùng vào Firestore với vai trò mặc định (không phải admin)
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email.trim(),
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng ký: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      rethrow;
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      print('Lỗi gửi email đặt lại mật khẩu: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
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
    } on FirebaseAuthException catch (e) {
      print('Lỗi cập nhật mật khẩu: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi cập nhật mật khẩu: $e');
      rethrow;
    }
  }

  /// Theo dõi trạng thái đăng nhập của người dùng
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ánh xạ lỗi FirebaseAuthException thành thông báo thân thiện
  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Không tìm thấy tài khoản với email này');
      case 'wrong-password':
        return Exception('Mật khẩu không chính xác');
      case 'invalid-email':
        return Exception('Email không hợp lệ');
      case 'user-disabled':
        return Exception('Tài khoản đã bị vô hiệu hóa');
      case 'email-already-in-use':
        return Exception('Email đã được sử dụng');
      case 'weak-password':
        return Exception('Mật khẩu quá yếu');
      case 'operation-not-allowed':
        return Exception('Thao tác không được phép');
      default:
        return Exception('Lỗi: ${e.message}');
    }
  }
}
