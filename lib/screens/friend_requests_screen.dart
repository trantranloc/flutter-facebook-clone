import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:go_router/go_router.dart';

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

    final snapshot =
        await _firestore
            .collection('users')
            .where('pendingRequests', arrayContains: currentUser.uid)
            .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> _handleFriendRequest(String friendUid, bool accept) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      if (accept) {
        // Thêm vào danh sách bạn bè của cả hai người dùng
        await _firestore.collection('users').doc(currentUser.uid).update({
          'friends': FieldValue.arrayUnion([friendUid]),
        });
        await _firestore.collection('users').doc(friendUid).update({
          'friends': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      // Xóa khỏi danh sách lời mời kết bạn
      await _firestore.collection('users').doc(currentUser.uid).update({
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });

      // Refresh danh sách
      setState(() {
        _pendingRequestsFuture = _fetchPendingRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Đã chấp nhận lời mời' : 'Đã từ chối lời mời'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời kết bạn'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
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
                    onPressed: () {
                      setState(() {
                        _pendingRequestsFuture = _fetchPendingRequests();
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final pendingRequests = snapshot.data ?? [];
          if (pendingRequests.isEmpty) {
            return const Center(
              child: Text(
                'Không có lời mời kết bạn nào',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final user = pendingRequests[index];
              return ListTile(
                onTap: () {
                  context.push('/other-profile/${user.uid}');
                },
                leading: GestureDetector(
                  onTap: () {
                    context.push('/other-profile/${user.uid}');
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleFriendRequest(user.uid, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Chấp nhận'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleFriendRequest(user.uid, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Từ chối'),
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
