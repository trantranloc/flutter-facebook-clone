import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import Firestore
import 'package:flutter_facebook_clone/models/User.dart'; // Import UserModel

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

  /// Lưu thông tin người dùng vào Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      print('Lỗi khi lưu user: $e');
      throw Exception('Không thể lưu thông tin người dùng: $e');
    }
  }
Future<UserModel?> getUser(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      } else {
        print('Không tìm thấy thông tin người dùng với UID: $uid');
      }
      return null;
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: $e');
    }
  }
  Future<List<UserModel>> getFriends(List<String> friendUids) async {
    try {
      List<UserModel> friends = [];
      for (String uid in friendUids) {
        final user = await getUser(uid);
        if (user != null) {
          friends.add(user);
        }
      }
      return friends;
    } catch (e) {
      print('Lỗi khi lấy danh sách bạn bè: $e');
      return [];
    }
  }
  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Theo dõi trạng thái đăng nhập của người dùng
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
