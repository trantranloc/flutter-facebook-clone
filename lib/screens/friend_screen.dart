import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_facebook_clone/screens/other_user_profile_screen.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<UserModel>> _suggestedFriendsFuture;
  final Set<String> _sentRequestUids = {};

  @override
  void initState() {
    super.initState();
    _suggestedFriendsFuture = _fetchSuggestedFriends();
    _initializeSentRequests();
  }

  Future<void> _initializeSentRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .where('pendingRequests', arrayContains: currentUser.uid)
            .get();

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _sentRequestUids.clear();
        for (var doc in snapshot.docs) {
          _sentRequestUids.add(doc.id);
        }
      });
    });
  }

  Future<List<UserModel>> _fetchSuggestedFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    final QuerySnapshot snapshot =
        await _firestore
            .collection('users')
            .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
            .limit(20) // Giới hạn 20 người dùng
            .get();

    // Debug logs
    print('Current user ID: ${currentUser.uid}');
    print('Found ${snapshot.docs.length} users');

    final users =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print('User data for ${doc.id}: $data'); // Debug log
          return UserModel.fromMap(data);
        }).toList();

    print(
      'Users: ${users.map((u) => '${u.name} (${u.uid})').join(', ')}',
    ); // Debug log
    return users;
  }

  Future<void> _toggleFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để thêm bạn bè')),
      );
      return;
    }

    try {
      if (_sentRequestUids.contains(friendUid)) {
        await _firestore.collection('users').doc(friendUid).update({
          'pendingRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _sentRequestUids.remove(friendUid);
          });
        });

      } else {
        await _firestore.collection('users').doc(friendUid).update({
          'pendingRequests': FieldValue.arrayUnion([currentUser.uid]),
        });
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _sentRequestUids.add(friendUid);
          });
        });

      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _retryFetch() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _suggestedFriendsFuture = _fetchSuggestedFriends();
        _initializeSentRequests();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<UserModel>>(
        future: _suggestedFriendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _retryFetch,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final suggestedFriends = snapshot.data ?? [];

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: TextButton(
                              onPressed: () {
                                context.push('/friend-requests');
                              },
                              child: const Text(
                                'Lời mời kết bạn',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: TextButton(
                              onPressed: () {
                                context.push('/list-friend');
                              },
                              child: const Text(
                                'Bạn bè',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Những người bạn có thể biết',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ...suggestedFriends.map(
                (user) => Column(
                  children: [
                    ListTile(
                      onTap: () {
                        context.go('/other-profile/${user.uid}');
                      },
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OtherUserProfileScreen(
                                    key: ValueKey(user.uid), 
                                    uid: user.uid,
                                  ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            user.avatarUrl.isNotEmpty
                                ? user.avatarUrl
                                : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                          ),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text('${user.friends.length} bạn chung'),
                      trailing:
                          _sentRequestUids.contains(user.uid)
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => _toggleFriendRequest(user.uid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Hủy lời mời'),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => _toggleFriendRequest(user.uid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1877F2),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Thêm bạn bè'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Gỡ'),
                                  ),
                                ],
                              ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
