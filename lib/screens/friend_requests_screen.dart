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

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem lời mời kết bạn')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời kết bạn'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching user data: ${snapshot.error}'); // Debug log
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Không tìm thấy dữ liệu người dùng'),
            );
          }

          final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> pendingRequestUids = List<String>.from(
            currentUserData['pendingRequests'] ?? [],
          );
          print('Pending request UIDs: $pendingRequestUids'); // Debug log

          if (pendingRequestUids.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Không có lời mời kết bạn nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Khi ai đó gửi lời mời kết bạn, nó sẽ xuất hiện ở đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                _firestore
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: pendingRequestUids)
                    .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                print(
                  'Error fetching users: ${userSnapshot.error}',
                ); // Debug log
                return Center(
                  child: Text(
                    'Lỗi khi tải thông tin người dùng: ${userSnapshot.error}',
                  ),
                );
              }

              final pendingRequests =
                  userSnapshot.data!.docs
                      .map(
                        (doc) => UserModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();
              print(
                'Pending requests: ${pendingRequests.map((u) => u.name).toList()}',
              ); // Debug log

              if (pendingRequests.isEmpty) {
                return const Center(
                  child: Text('Không có lời mời kết bạn nào'),
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
                          onPressed:
                              () => _handleFriendRequest(user.uid, false),
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
          );
        },
      ),
    );
  }

  Future<void> _handleFriendRequest(String friendUid, bool accept) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      if (accept) {
        // Thêm vào danh sách bạn bè của cả hai người dùng
        await _firestore.collection('users').doc(currentUser.uid).update({
          'friends': FieldValue.arrayUnion([friendUid]),
          'pendingRequests': FieldValue.arrayRemove([friendUid]),
        });
        await _firestore.collection('users').doc(friendUid).update({
          'friends': FieldValue.arrayUnion([currentUser.uid]),
          'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        // Xóa lời mời từ pendingRequests của người nhận
        await _firestore.collection('users').doc(currentUser.uid).update({
          'pendingRequests': FieldValue.arrayRemove([friendUid]),
        });
        // Xóa lời mời từ sentRequests của người gửi
        await _firestore.collection('users').doc(friendUid).update({
          'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Đã chấp nhận lời mời' : 'Đã từ chối lời mời'),
        ),
      );
    } catch (e) {
      print('Error handling friend request: $e'); // Debug log
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }
}
