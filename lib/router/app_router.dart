import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/router/admin_router.dart';
import 'package:flutter_facebook_clone/router/user_router.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  // Singleton instance
  static final AppRouter _instance = AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  AppRouter._internal();

  // Lấy router thích hợp dựa trên trạng thái của UserProvider
  static GoRouter getRouter(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Sử dụng adminRouter nếu useAdminRouter là true
    if (userProvider.useAdminRouter) {
      debugPrint('Using admin router');
      return adminRouter;
    } else {
      debugPrint('Using user router');
      return userRouter;
    }
  }

  // Chuyển đổi sang admin router
  static void switchToAdminRouter(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.useAdminRouter) {
      debugPrint('Switching to admin router');
      userProvider.setAdminRouter(true);
    }
  }

  // Chuyển đổi sang user router
  static void switchToUserRouter(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.useAdminRouter) {
      debugPrint('Switching to user router');
      userProvider.setAdminRouter(false);
    }
  }

  // Kiểm tra quyền admin và chuyển router phù hợp
  static Future<void> checkAndSetAdminRouter(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.checkAdminStatus();

    if (userProvider.isAdmin && !userProvider.useAdminRouter) {
      debugPrint('Setting admin router to true because user is admin');
      userProvider.setAdminRouter(true);
    }
  }
}
