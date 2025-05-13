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

  // Lưu trữ trạng thái
  late Stream<List<UserModel>> _suggestedFriendsStream;
  final Set<String> _friendUids = {};
  final Set<String> _sentRequestUids = {};
  final Set<String> _receivedRequestUids = {};

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _initializeFriendAndRequestData();
  }

  void _initializeStreams() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Stream cho danh sách gợi ý bạn bè
    _suggestedFriendsStream = _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .where(
                (user) => !_friendUids.contains(user.uid),
              ) // Loại bỏ bạn bè
              .toList();
        });
  }

  Future<void> _initializeFriendAndRequestData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Lấy dữ liệu người dùng hiện tại
    final currentUserDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data();
    if (currentUserData == null) return;

    if (!mounted) return;

    setState(() {
      _friendUids.clear();
      _friendUids.addAll(List<String>.from(currentUserData['friends'] ?? []));

      _sentRequestUids.clear();
      _sentRequestUids.addAll(
        List<String>.from(currentUserData['sentRequests'] ?? []),
      );

      _receivedRequestUids.clear();
      _receivedRequestUids.addAll(
        List<String>.from(currentUserData['pendingRequests'] ?? []),
      );
    });
  }

  Future<void> _toggleFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để thêm bạn bè')),
      );
      return;
    }

    if (_friendUids.contains(friendUid)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Các bạn đã là bạn bè')));
      return;
    }

    try {
      if (_sentRequestUids.contains(friendUid)) {
        // Hủy lời mời đã gửi
        await _firestore.collection('users').doc(friendUid).update({
          'pendingRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
        await _firestore.collection('users').doc(currentUser.uid).update({
          'sentRequests': FieldValue.arrayRemove([friendUid]),
        });
        // Xóa thông báo tương ứng (nếu có)
        final notificationSnapshot =
            await _firestore
                .collection('notifications')
                .where('userId', isEqualTo: friendUid)
                .where('senderId', isEqualTo: currentUser.uid)
                .where('type', isEqualTo: 'friend_request')
                .get();
        for (var doc in notificationSnapshot.docs) {
          await doc.reference.delete();
        }
        setState(() {
          _sentRequestUids.remove(friendUid);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy lời mời kết bạn')));
      } else {
        // Gửi lời mời
        await _firestore.collection('users').doc(friendUid).update({
          'pendingRequests': FieldValue.arrayUnion([currentUser.uid]),
        });
        await _firestore.collection('users').doc(currentUser.uid).update({
          'sentRequests': FieldValue.arrayUnion([friendUid]),
        });

        // Lấy thông tin người gửi để tạo thông báo
        final senderDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        final senderData = senderDoc.data();
        if (senderData != null) {
          final senderName = senderData['name'] ?? 'Người dùng';
          final senderAvatarUrl =
              senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

          // Tạo thông báo cho người nhận
          await _firestore.collection('notifications').add({
            'userId': friendUid, // Người nhận thông báo
            'senderId': currentUser.uid, // Người gửi lời mời
            'senderName': senderName,
            'senderAvatarUrl': senderAvatarUrl,
            'action': 'đã gửi lời mời kết bạn.',
            'type': 'friend_request',
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            'date': 'Hôm nay', // Có thể tính toán dựa trên timestamp nếu cần
          });
        }

        setState(() {
          _sentRequestUids.add(friendUid);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời kết bạn')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _acceptFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Thêm vào danh sách bạn bè của cả hai
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([friendUid]),
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
        'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      setState(() {
        _friendUids.add(friendUid);
        _receivedRequestUids.remove(friendUid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _rejectFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Xóa lời mời
      await _firestore.collection('users').doc(currentUser.uid).update({
        'pendingRequests': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      setState(() {
        _receivedRequestUids.remove(friendUid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối lời mời kết bạn')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Xóa khỏi danh sách bạn bè của cả hai
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayRemove([currentUser.uid]),
      });

      setState(() {
        _friendUids.remove(friendUid);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa bạn bè')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _retryFetch() {
    setState(() {
      _initializeStreams();
      _initializeFriendAndRequestData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<UserModel>>(
        stream: _suggestedFriendsStream,
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
              // Thanh điều hướng
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                  ],
                ),
              ),
              // Tiêu đề danh sách gợi ý
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 8.0),
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
              // Danh sách người dùng
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
                      trailing: _buildTrailingWidget(user.uid),
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

  Widget _buildTrailingWidget(String userUid) {
    if (_friendUids.contains(userUid)) {
      // Đã là bạn bè
      return ElevatedButton(
        onPressed: () => _removeFriend(userUid),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
        ),
        child: const Text('Xóa bạn bè'),
      );
    } else if (_sentRequestUids.contains(userUid)) {
      // Đã gửi lời mời
      return ElevatedButton(
        onPressed: () => _toggleFriendRequest(userUid),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
        ),
        child: const Text('Hủy lời mời'),
      );
    } else if (_receivedRequestUids.contains(userUid)) {
      // Nhận được lời mời
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _acceptFriendRequest(userUid),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Chấp nhận'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _rejectFriendRequest(userUid),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      );
    } else {
      // Chưa có mối quan hệ
      return ElevatedButton(
        onPressed: () => _toggleFriendRequest(userUid),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          foregroundColor: Colors.white,
        ),
        child: const Text('Thêm bạn bè'),
      );
    }
  }
}
