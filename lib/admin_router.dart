import 'package:flutter_facebook_clone/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_choice_screen.dart';
import 'package:flutter_facebook_clone/admin/screens/post_management_screen.dart';
import 'package:flutter_facebook_clone/screens/login_screen.dart';
import 'package:flutter_facebook_clone/admin/screens/user_management_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter adminRouter = GoRouter(
  initialLocation: '/admin', // Gốc là /admin
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/admin'),

    // Đường dẫn đăng nhập
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Nhánh admin
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'choice',
          name: 'admin_choice',
          builder: (context, state) => const AdminChoiceScreen(),
        ),
        GoRoute(
          path: 'overview',
          name: 'overview',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: 'user-management',
          name: 'user_management',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: 'post-management',
          name: 'post_management',
          builder: (context, state) => const PostManagementScreen(),
        ),
      ],
    ),
  ],
);
