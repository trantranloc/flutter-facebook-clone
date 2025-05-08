import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:flutter_facebook_clone/screens/friend_screen.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<UserModel>> _pendingRequestsFuture;

  @override
  void initState() {
    super.initState();
    _pendingRequestsFuture = _fetchPendingRequests();
  }

  Future<List<UserModel>> _fetchPendingRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    // Fetch the current user's document to get their pendingRequests list
    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
    final List<String> pendingRequestUids = List<String>.from(currentUserData?['pendingRequests'] ?? []);

    if (pendingRequestUids.isEmpty) return [];

    // Fetch the user documents for all pending requests
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: pendingRequestUids)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> _acceptFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([friendUid]),
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });
      setState(() {
        _pendingRequestsFuture = _fetchPendingRequests();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận bạn bè')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      setState(() {
        _pendingRequestsFuture = _fetchPendingRequests();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa lời mời')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _retryFetch() {
    setState(() {
      _pendingRequestsFuture = _fetchPendingRequests();
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
              MaterialPageRoute(builder: (context) => const FriendScreen()),
            );
          },
        ),
        title: const Text(
          'Lời mời kết bạn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _pendingRequestsFuture,
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
          final pendingRequests = snapshot.data ?? [];

          if (pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/friend_icon.png', width: 100, height: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'Không có lời mời',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Những người dùng gửi bạn lời mời kết bạn sẽ\nxuất hiện ở đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const FriendScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Xem gợi ý kết bạn'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final user = pendingRequests[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    user.avatarUrl.isNotEmpty
                        ? user.avatarUrl
                        : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                  ),
                ),
                title: Text(user.name),
                subtitle: const Text('1 phút'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptFriendRequest(user.uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Xác nhận'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _rejectFriendRequest(user.uid),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}