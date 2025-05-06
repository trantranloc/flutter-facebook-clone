import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/screens/profile_screen.dart';
import 'package:flutter_facebook_clone/widgets/avatar_selection_screen.dart';
import 'package:flutter_facebook_clone/widgets/email_screen.dart';
import 'package:flutter_facebook_clone/screens/friend_screen.dart';
import 'package:flutter_facebook_clone/screens/home_screen.dart';
import 'package:flutter_facebook_clone/screens/login_screeen.dart';
import 'package:flutter_facebook_clone/screens/menu_screen.dart';
import 'package:flutter_facebook_clone/screens/message_screen.dart';
import 'package:flutter_facebook_clone/screens/notification_screen.dart';
import 'package:flutter_facebook_clone/widgets/password_screen.dart';
import 'package:flutter_facebook_clone/widgets/personal_info_screen.dart';
import 'package:flutter_facebook_clone/screens/search_screen.dart';
import 'package:flutter_facebook_clone/widgets/verification_sceen.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentPath = state.uri.toString();
    final protectedRoutes = ['/', '/friend', '/message', '/notification', '/menu', '/profile', '/search'];

    // Nếu chưa đăng nhập và cố gắng vào tuyến đường được bảo vệ, chuyển hướng đến /login
    if (!isLoggedIn && protectedRoutes.contains(currentPath)) {
      return '/login';
    }
    // Nếu đã đăng nhập và ở trang đăng nhập, chuyển hướng đến /home
    if (isLoggedIn && currentPath == '/login') {
      return '/';
    }
    return null; // Không chuyển hướng
  },
  routes: [
    // Không cần thanh điều hướng và appBar
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/personal-info',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(path: '/email', builder: (context, state) => const EmailScreen()),
    GoRoute(
      path: '/verification',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/password',
      builder: (context, state) => const PasswordScreen(),
    ),
    GoRoute(
      path: '/avatar',
      builder: (context, state) => const AvatarSelectionScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      // Có thanh điều hướng và appBar
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/friend',
          builder: (context, state) => const FriendScreen(),
        ),
        GoRoute(
          path: '/message',
          builder: (context, state) => const MessageScreen(),
        ),
        GoRoute(
          path: '/notification',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
      ],
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final uid = state.extra as String;
        return ProfileScreen(uid: uid);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  static const tabs = ['/', '/friend', '/message', '/notification', '/menu'];

  static const tabIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.userGroup,
    FontAwesomeIcons.comment,
    FontAwesomeIcons.bell,
    FontAwesomeIcons.bars,
  ];

  int _locationToIndex(String location) {
    final index = tabs.indexWhere((t) => location.startsWith(t));
    return index < 0 ? 0 : index;
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.penToSquare, color: Color(0xFF1877F2)),
                title: const Text('Bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tạo bài viết'),
                      content: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Bạn đang nghĩ gì?',
                        ),
                        maxLines: 3,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Lưu bài viết
                            Navigator.pop(context);
                          },
                          child: const Text('Đăng'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.camera, color: Color(0xFF1877F2)),
                title: const Text('Tin'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tạo tin'),
                      content: const Text(
                        'Chức năng tạo tin chưa được triển khai.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(GoRouterState.of(context).uri.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF1877F2), // Facebook blue
        title: const Text(
          'Facebook',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 30, color: Colors.white),
            onPressed: () => _showCreateOptions(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 25, color: Colors.white),
            onPressed: () {
              context.go('/search');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isSelected = currentIndex == index;
                return InkWell(
                  onTap: () => context.go(tabs[index]),
                  splashColor: const Color(0xFF1877F2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.7,
                          duration: const Duration(milliseconds: 200),
                          child: FaIcon(
                            tabIcons[index],
                            color: isSelected ? const Color(0xFF1877F2) : Colors.grey[600],
                            size: 24,
                          ),
                        ),                      
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: child),
        ],
      ),
    );
  }
}