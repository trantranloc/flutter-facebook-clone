import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Tải dữ liệu người dùng
  Future<void> loadUserData(String uid, AuthService auth) async {
    // Kiểm tra cache trước
    UserModel? cachedUser = await _getCachedUser();
    if (cachedUser != null) {
      _userModel = cachedUser;
      _isLoading = false;
      notifyListeners();
      // Làm mới dữ liệu nền nếu cần (tùy chọn)
      _refreshUserData(uid, auth);
      return;
    }

    // Tải từ Firebase nếu không có cache
    _isLoading = true;
    notifyListeners();
    try {
      final userModel = await auth.getUser(uid);
      _userModel = userModel;
      if (userModel != null) {
        await _cacheUser(userModel); // Lưu vào cache
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Xóa dữ liệu người dùng (khi đăng xuất)
  Future<void> clearUser() async {
    _userModel = null;
    _isLoading = false;
    await _clearCache(); // Xóa cache
    notifyListeners();
  }

  // Lưu UserModel vào SharedPreferences
  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  // Lấy UserModel từ SharedPreferences
  Future<UserModel?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('cached_user');
    if (userData != null) {
      return UserModel.tryParse(jsonDecode(userData));
    }
    return null;
  }

  // Xóa cache
  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  // Làm mới dữ liệu từ Firebase (tùy chọn)
  Future<void> _refreshUserData(String uid, AuthService auth) async {
    try {
      final userModel = await auth.getUser(uid);
      if (userModel != null) {
        _userModel = userModel;
        await _cacheUser(userModel);
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi làm mới dữ liệu: $e');
    }
  }

  void updateUser(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }
}
