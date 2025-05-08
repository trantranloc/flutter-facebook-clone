import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/models/User.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lưu thông tin người dùng vào Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      print('Lỗi khi lưu user: $e');
      throw Exception('Không thể lưu thông tin người dùng: $e');
    }
  }

  /// Lấy thông tin người dùng theo UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        print('Không tìm thấy thông tin người dùng với UID: $uid');
      }
      return null;
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: $e');
    }
  }

  /// Lấy danh sách bạn bè
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

  /// Cập nhật avatar người dùng
  Future<void> updateUserAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      print('Lỗi khi cập nhật avatar: $e');
      rethrow;
    }
  }

  /// Cập nhật ảnh bìa người dùng
  Future<void> updateUserCover(String uid, String coverUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'coverUrl': coverUrl,
      });
    } catch (e) {
      print('Lỗi khi cập nhật ảnh bìa: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin cá nhân
  Future<void> updateUserInfo(String uid, String name, String gender) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'gender': gender,
      });
    } catch (e) {
      print('Lỗi khi cập nhật thông tin cá nhân: $e');
      rethrow;
    }
  }

  /// Cập nhật tiểu sử
  Future<void> updateUserBio(String uid, String bio) async {
    try {
      await _firestore.collection('users').doc(uid).update({'bio': bio});
    } catch (e) {
      print('Lỗi khi cập nhật tiểu sử: $e');
      rethrow;
    }
  }
}
