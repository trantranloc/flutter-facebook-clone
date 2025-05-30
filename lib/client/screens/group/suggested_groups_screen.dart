import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_home_screen.dart';
import 'package:flutter_facebook_clone/models/Group.dart';

class SuggestedGroupsScreen extends StatefulWidget {
  const SuggestedGroupsScreen({super.key});

  @override
  State<SuggestedGroupsScreen> createState() => _SuggestedGroupsScreenState();
}

class _SuggestedGroupsScreenState extends State<SuggestedGroupsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Group>> _fetchSuggestedGroups() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    Query query = _firestore.collection('groups');

    try {
      query = query.orderBy('createdAt', descending: true);
    } catch (e) {
      // Fallback or no sorting if createdAt is not available
    }

    final snapshot = await query.get();

    // Lấy tất cả nhóm
    final allGroups =
        snapshot.docs
            .map(
              (doc) =>
                  Group.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

    // Lọc bỏ các nhóm mà người dùng đã tham gia hoặc đã gửi yêu cầu tham gia
    return allGroups.where((group) {
      final isMember = group.members.contains(user.uid);
      final hasPendingRequest = group.pendingRequests.contains(user.uid);
      return !isMember &&
          !hasPendingRequest; // Chỉ giữ các nhóm chưa tham gia và chưa gửi yêu cầu
    }).toList();
  }

  Future<void> _joinGroup(Group group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (group.privacy == GroupPrivacy.public) {
        // Nhóm công khai: Thêm trực tiếp vào members
        await _firestore.collection('groups').doc(group.id).update({
          'members': FieldValue.arrayUnion([user.uid]),
          'memberCount': FieldValue.increment(1),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tham gia nhóm'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Nhóm riêng tư: Thêm vào pendingRequests
        await _firestore.collection('groups').doc(group.id).update({
          'pendingRequests': FieldValue.arrayUnion([user.uid]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu tham gia'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh danh sách sau khi tham gia hoặc gửi yêu cầu
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi ${group.privacy == GroupPrivacy.public ? "tham gia nhóm" : "gửi yêu cầu tham gia"}: $e',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _retryFetch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Nhóm dành cho bạn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Group>>(
            future: _fetchSuggestedGroups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                String errorMsg = 'Đã xảy ra lỗi khi tải nhóm';
                if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
                  errorMsg =
                      'Lỗi truy vấn: Vui lòng tạo chỉ mục Firestore tại đây: https://console.firebase.google.com';
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMsg,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _retryFetch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              final groups = snapshot.data ?? [];

              if (user == null) {
                return const Center(
                  child: Text(
                    'Vui lòng đăng nhập để xem nhóm',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (groups.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có nhóm nào để hiển thị',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView(
                children: [
                  // Group List
                  ...groups.map(
                    (group) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              group.coverImageUrl.isNotEmpty
                                  ? group.coverImageUrl
                                  : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.group,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            group.description.isNotEmpty
                                ? group.description
                                : 'Hơn ${group.members.length} thành viên',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: TextButton(
                            onPressed: () => _joinGroup(group),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1877F2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              group.privacy == GroupPrivacy.public
                                  ? 'Tham gia'
                                  : 'Tham gia',
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        GroupHomeScreen(groupId: group.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
