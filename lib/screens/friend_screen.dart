import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:flutter_facebook_clone/screens/add_friend_screen.dart';
import 'package:flutter_facebook_clone/screens/list_friend_screen.dart';
import 'package:flutter_facebook_clone/screens/profile_screen.dart'; // Import ProfileScreen

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

    final snapshot = await _firestore
        .collection('users')
        .where('pendingRequests', arrayContains: currentUser.uid)
        .get();

    setState(() {
      _sentRequestUids.clear();
      for (var doc in snapshot.docs) {
        _sentRequestUids.add(doc.id);
      }
    });
  }

  Future<List<UserModel>> _fetchSuggestedFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
    final List<String> currentUserFriends = List<String>.from(currentUserData?['friends'] ?? []);

    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((user) => !currentUserFriends.contains(user.uid))
        .toList();
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
        setState(() {
          _sentRequestUids.remove(friendUid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy lời mời')),
        );
      } else {
        await _firestore.collection('users').doc(friendUid).update({
          'pendingRequests': FieldValue.arrayUnion([currentUser.uid]),
        });
        setState(() {
          _sentRequestUids.add(friendUid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _retryFetch() {
    setState(() {
      _suggestedFriendsFuture = _fetchSuggestedFriends();
      _initializeSentRequests();
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FriendRequestsScreen(),
                                  ),
                                );
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FriendListScreen(),
                                  ),
                                );
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
                    Text(
                      'Những người bạn có thể biết',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ...suggestedFriends.map((user) => Column(
                children: [
                  ListTile(
                    onTap: () {
                      // Navigate to ProfileScreen when avatar or name is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: user.uid),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        user.avatarUrl.isNotEmpty
                            ? user.avatarUrl
                            : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.friends.length} bạn chung'),
                    trailing: _sentRequestUids.contains(user.uid)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _toggleFriendRequest(user.uid),
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
                                onPressed: () => _toggleFriendRequest(user.uid),
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
              )).toList(),
            ],
          );
        },
      ),
    );
  }
}