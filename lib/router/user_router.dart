import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/client/screens/group_chat_screen.dart';
import 'package:flutter_facebook_clone/client/screens/post_screen.dart';
import 'package:flutter_facebook_clone/client/screens/profile_screen.dart';
import 'package:flutter_facebook_clone/widgets/avatar_selection_screen.dart';
import 'package:flutter_facebook_clone/widgets/email_screen.dart';
import 'package:flutter_facebook_clone/client/screens/friend_screen.dart';
import 'package:flutter_facebook_clone/client/screens/home_screen.dart';
import 'package:flutter_facebook_clone/client/screens/login_screen.dart';
import 'package:flutter_facebook_clone/client/screens/menu_screen.dart';
import 'package:flutter_facebook_clone/client/screens/message_screen.dart';
import 'package:flutter_facebook_clone/client/screens/notification_screen.dart';
import 'package:flutter_facebook_clone/widgets/password_screen.dart';
import 'package:flutter_facebook_clone/widgets/personal_info_screen.dart';
import 'package:flutter_facebook_clone/client/screens/search_screen.dart';
import 'package:flutter_facebook_clone/widgets/verification_sceen.dart';
import 'package:flutter_facebook_clone/client/screens/chat_screen.dart';
import 'package:flutter_facebook_clone/client/screens/list_friend_screen.dart';
import 'package:flutter_facebook_clone/client/screens/edit_profile_screen.dart';
import 'package:flutter_facebook_clone/client/screens/forgot_password_screen.dart';
import 'package:flutter_facebook_clone/client/screens/verify_reset_code_screen.dart';
import 'package:flutter_facebook_clone/client/screens/reset_password_screen.dart';
import 'package:flutter_facebook_clone/client/screens/other_user_profile_screen.dart';
import 'package:flutter_facebook_clone/client/screens/friend_requests_screen.dart';
import 'package:flutter_facebook_clone/client/screens/setting_screen.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_choice_screen.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/client/screens/game_selection_screen.dart';
import 'package:flutter_facebook_clone/client/screens/game_word_chain_screen.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GoRouter userRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentPath = state.uri.toString();
    final protectedRoutes = [
      '/',
      '/friend',
      '/message',
      '/notification',
      '/menu',
      '/profile',
      '/search',
      '/other-profile',
      '/friend-requests',
      '/list-friend',
    ];
    final registrationRoutes = [
      '/personal-info',
      '/email',
      '/verification',
      '/password',
      '/avatar',
    ];
    // Cho phép các route đăng ký
    if (registrationRoutes.any((route) => currentPath.startsWith(route))) {
      return null;
    }

    // Nếu chưa đăng nhập và cố gắng vào route được bảo vệ
    if (!isLoggedIn &&
        protectedRoutes.any((route) => currentPath.startsWith(route))) {
      return '/login';
    }

    // Nếu đã đăng nhập và ở trang đăng nhập
    if (isLoggedIn && currentPath == '/login') {
      // Kiểm tra admin status trước khi redirect
      if (context.mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // Đợi admin status được load (nếu chưa có)
        if (userProvider.userModel != null && userProvider.isAdmin) {
          return '/admin/choice';
        }
      }
      return '/';
    }

    // Handle admin paths - cho phép truy cập nếu là admin
    if (currentPath.startsWith('/admin')) {
      if (context.mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (!userProvider.isAdmin) {
          return '/'; // Chuyển về trang chủ nếu không phải admin
        }
      }
      return null; // Cho phép tiếp tục nếu là admin
    }

    return null;
  },
  routes: [
    // Không cần thanh điều hướng và appBar
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-reset-code',
      builder: (context, state) => const VerifyResetCodeScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
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
        final uid = state.extra as String?;
        if (uid == null || uid.isEmpty) {
          // Trường hợp không có UID hoặc UID rỗng
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            return ProfileScreen(uid: currentUser.uid);
          } else {
            // Nếu không có user đang đăng nhập
            Future.microtask(() => context.go('/login'));
            return const Center(child: CircularProgressIndicator());
          }
        }
        return ProfileScreen(uid: uid);
      },
    ),
    GoRoute(
      path: '/edit-profile/:editType',
      builder: (context, state) {
        final editType = state.pathParameters['editType'] ?? '';
        return EditProfileScreen(editType: editType);
      },
    ),
    GoRoute(
      path: '/message',
      builder: (context, state) => const MessageScreen(),
      routes: [
        GoRoute(
          path: 'chat/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ChatScreen(userId: userId);
          },
        ),
        GoRoute(
          path: 'group/:groupId',
          builder:
              (context, state) =>
                  GroupChatScreen(groupId: state.pathParameters['groupId']!),
        ),
        // GoRoute(
        //       path: 'group/:groupId',
        //       builder: (context, state) {
        //         final groupId = state.pathParameters['groupId']!;
        //         return GroupChatScreen(groupId: groupId);
        //       },
        //     ),
        // GoRoute(
        //   path: 'group/:groupId/details',
        //   builder: (context, state) {
        //     final groupId = state.pathParameters['groupId']!;
        //     return GroupDetailsScreen(groupId: groupId);
        //   },
        // ),
      ],
    ),
    GoRoute(
      path: '/list-friend',
      builder: (context, state) => const FriendListScreen(),
    ),
    GoRoute(
      path: '/friend-requests',
      builder: (context, state) => const FriendRequestsScreen(),
    ),
    GoRoute(
      path: '/other-profile/:uid',
      builder: (context, state) {
        final uid = state.pathParameters['uid'];
        if (uid == null || uid.isEmpty) {
          // Nếu không có UID, chuyển về trang chủ
          Future.microtask(() => context.go('/'));
          return const Center(child: CircularProgressIndicator());
        }
        print('Navigating to profile with UID: $uid'); // Debug log
        return OtherUserProfileScreen(uid: uid);
      },
    ),
    GoRoute(
      path: '/setting',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/choice',
      builder: (context, state) => const AdminChoiceScreen(),
    ),
    GoRoute(
      path: '/game-selection',
      builder: (context, state) => const GameSelectionScreen(),
    ),
    GoRoute(
      path: '/game-word-chain',
      builder: (context, state) => const GameWordChainScreen(),
    ),
    GoRoute(
      path: '/post/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        return PostScreen(postId: postId);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatefulWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  static const tabs = ['/', '/friend', '/message', '/notification', '/menu'];

  static const tabIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.userGroup,
    FontAwesomeIcons.comment,
    FontAwesomeIcons.bell,
    FontAwesomeIcons.bars,
  ];

  // Determine which tab is selected based on the current location
  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    // Handle exact matches first
    int index = tabs.indexOf(location);
    if (index != -1) return index;

    // Handle nested routes
    if (location.startsWith('/message/')) {
      return 2; // Index of message tab
    }

    // Handle other partial matches
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i]) && tabs[i] != '/') {
        return i;
      }
    }

    // Default to home if no match
    return location == '/' ? 0 : -1;
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
                leading: const FaIcon(
                  FontAwesomeIcons.penToSquare,
                  color: Color(0xFF1877F2),
                ),
                title: const Text('Bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
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
                leading: const FaIcon(
                  FontAwesomeIcons.camera,
                  color: Color(0xFF1877F2),
                ),
                title: const Text('Tin'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
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
    final selectedIndex = _getSelectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Theme-aware backgroun
      appBar: AppBar(
        backgroundColor: theme.primaryColorDark,
        title: const Text(
          'LiteLine',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color.fromARGB(255, 237, 119, 255),
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.plus,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () => _showCreateOptions(context),
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 25,
              color: Colors.white,
            ),
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
            color: theme.cardColor, // Theme-aware container color
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    context.go(tabs[index]);
                  },
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: FaIcon(
                      tabIcons[index],
                      color:
                          isSelected
                              ? theme
                                  .primaryColor // Theme-aware selected icon color
                              : theme
                                  .unselectedWidgetColor, // Theme-aware unselected icon color
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
