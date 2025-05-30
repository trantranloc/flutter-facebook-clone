import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_screen_one.dart';
import 'package:flutter_facebook_clone/client/screens/group/suggested_groups_screen.dart';
import 'package:flutter_facebook_clone/client/screens/menu_screen.dart';
import 'package:flutter_facebook_clone/client/screens/search_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_invitations_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  int _selectedTab = 0; // 0 for Groups, 1 for Discover, 2 for Invitations
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Stream<int> _getPendingInvitationsCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }
    return _firestore
        .collectionGroup('invitations')
        .where('invitedUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          print('Error fetching invitations: $error');
          return 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          },
        ),
        title: const Text(
          'Nhóm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    index: 0,
                    icon: Icons.group,
                    label: 'Nhóm của bạn',
                  ),
                  const SizedBox(width: 20),
                  _buildTabButton(
                    index: 1,
                    icon: Icons.explore,
                    label: 'Dành cho bạn',
                  ),
                  const SizedBox(width: 20),
                  StreamBuilder<int>(
                    stream: _getPendingInvitationsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildTabButton(
                        index: 2,
                        icon: Icons.mail,
                        label: 'Lời mời',
                        badgeCount: count,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedTab == index ? const Color(0xFFE7F0FA) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1877F2), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF1877F2),
                    fontSize: 15,
                    fontWeight:
                        _selectedTab == index
                            ? FontWeight.bold
                            : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const GroupHomeScreenOne();
      case 1:
        return const SuggestedGroupsScreen();
      case 2:
        return const GroupInvitationsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
