import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          'Lời mời kết bạn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/friend_icon.png',
                    width: 100,
                    height: 100,
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
                      // Quay lại FriendScreen và yêu cầu làm mới
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Xem gợi ý kết bạn'),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
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

              final pendingRequests = userSnapshot.data!.docs
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
                return const Center(child: Text('Không có lời mời kết bạn'));
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
                    subtitle: const Text(
                      '1 phút',
                    ), // Có thể thay bằng thời gian thực
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
          );
        },
      ),
    );
  }

  Future<void> _acceptFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Thêm vào danh sách bạn bè của cả hai và xóa lời mời
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([friendUid]),
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
        'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xác nhận bạn bè')));
      // Không điều hướng, giữ người dùng ở lại FriendRequestsScreen
    } catch (e) {
      print('Error accepting friend request: $e'); // Debug log
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _rejectFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Xóa lời mời từ pendingRequests của người nhận
      await _firestore.collection('users').doc(currentUser.uid).update({
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      // Xóa lời mời từ sentRequests của người gửi
      await _firestore.collection('users').doc(friendUid).update({
        'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa lời mời')));
      // Không điều hướng, giữ người dùng ở lại FriendRequestsScreen
    } catch (e) {
      print('Error rejecting friend request: $e'); // Debug log
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }
}