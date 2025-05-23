import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  //Admin
  bool _isAdmin = false;
  bool _useAdminRouter = false;
  bool _isBlocked = false;

  bool get isAdmin => _isAdmin;
  bool get useAdminRouter => _useAdminRouter;
  bool get isBlocked => _isBlocked;
  void setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  Future<void> checkAdminStatus() async {
    try {
      _isAdmin = await AuthService().isAdmin();
      print('Admin status checked: $_isAdmin');
      _useAdminRouter = _isAdmin;
      if (_isAdmin && FirebaseAuth.instance.currentUser != null) {
        _useAdminRouter = true;
      }

      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
      _useAdminRouter = false;
      notifyListeners();
    }
  }

  void setAdminRouter(bool useAdminRouter) {
    _useAdminRouter = useAdminRouter;
    notifyListeners();
  }

  // Load user data
  Future<void> loadUserData(String uid, UserService userService) async {
    if (uid.isEmpty) {
      _error = 'Invalid user ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Kiểm tra trạng thái isBlocked trực tiếp từ Firestore
      bool isBlocked = await AuthService().isUserBlocked(uid);
      if (isBlocked) {
        _isBlocked = true;
        _userModel = null;
        _error = 'Tài khoản của bạn đã bị khóa';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Kiểm tra cache
      UserModel? cachedUser = await _getCachedUser();
      if (cachedUser != null && cachedUser.uid == uid) {
        _userModel = cachedUser;
        _isBlocked = cachedUser.isBlocked;
        _isLoading = false;
        _error = null;
        notifyListeners();
        // Làm mới dữ liệu ở chế độ nền
        _refreshUserData(uid, userService).catchError((e) {
          print('Background refresh failed: $e');
        });
        return;
      }

      // Tải dữ liệu từ Firestore nếu không có cache
      final userModel = await userService.getUser(uid);
      if (userModel != null) {
        _userModel = userModel;
        _isBlocked = userModel.isBlocked;
        await _cacheUser(userModel);
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetStatus() {
    _isAdmin = false;
    _useAdminRouter = false;
    _userModel = null;
    _error = null;
    notifyListeners();
  }

  // Clear user data (on logout)
  Future<void> clearUser() async {
    _userModel = null;
    _isLoading = false;
    _error = null;
    _isBlocked = false;
    await _clearCache();
    notifyListeners();
  }

  // Save UserModel to SharedPreferences
  Future<void> _cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(user.toJson()));
    } catch (e) {
      print('Failed to cache user data: $e');
    }
  }

  // Get UserModel from SharedPreferences
  Future<UserModel?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('cached_user');
      if (userData != null) {
        return UserModel.tryParse(jsonDecode(userData));
      }
    } catch (e) {
      print('Failed to get cached user data: $e');
    }
    return null;
  }

  // Clear cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  // Refresh data from Firebase
  Future<void> _refreshUserData(String uid, UserService userService) async {
    try {
      final userModel = await userService.getUser(uid);
      if (userModel != null) {
        _userModel = userModel;
        await _cacheUser(userModel);
        notifyListeners();
      }
    } catch (e) {
      print('Failed to refresh user data: $e');
    }
  }

  void updateUser(UserModel updatedUser) {
    _userModel = updatedUser;
    _error = null;
    notifyListeners();
  }
}
