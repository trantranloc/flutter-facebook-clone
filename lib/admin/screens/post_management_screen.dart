import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_scaffold.dart';
import 'package:flutter_facebook_clone/admin/screens/post_detail_screen.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _loadingPosts = {};

  // Hàm tạo bài viết giả và báo cáo giả
  Future<void> _addFakeReportedPost() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('posts')
              .where('userId', isEqualTo: 'E6UioEiM3nfO7cRGnJA3EJl5O4G3')
              .where('isReported', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        final postRef = _firestore.collection('posts').doc();
        await postRef.set({
          'userName': 'Nguyễn Văn A',
          'content': 'Nội dung nhạy cảm hoặc vi phạm chính sách cộng đồng',
          'isReported': true,
          'reportCount': 3,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': 'E6UioEiM3nfO7cRGnJA3EJl5O4G3',
        });

        // Tạo các báo cáo giả
        for (int i = 0; i < 3; i++) {
          await _firestore.collection('reports').add({
            'reportId': 'REP${DateTime.now().millisecondsSinceEpoch}_$i',
            'postId': postRef.id,
            'reportedBy': 'user_$i',
            'reason': 'Nội dung không phù hợp',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        await _logAdminAction(
          'create_fake_post',
          postRef.id,
          'Tạo bài viết giả',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo bài viết giả và báo cáo'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bài viết giả đã tồn tại'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo bài viết giả: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm ghi log hành động của admin
  Future<void> _logAdminAction(
    String action,
    String postId,
    String description,
  ) async {
    try {
      await _firestore.collection('admin_logs').add({
        'action': action,
        'postId': postId,
        'adminId': 'admin_user_id', // Thay bằng ID admin thực tế
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi khi ghi log: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý Bài viết',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _addFakeReportedPost,
              child: const Text('Tạo bài viết giả'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('posts')
                      .where('isReported', isEqualTo: true)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Không có bài viết bị báo cáo'),
                  );
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    final postId = posts[index].id;
                    final isLoading = _loadingPosts[postId] ?? false;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    post['userName']?.substring(0, 1) ?? 'U',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['userName'] ?? 'Không xác định',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(post['createdAt']),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post['content'] ?? 'Không có nội dung',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Số báo cáo: ${post['reportCount'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isLoading)
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  )
                                else
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => PostDetailScreen(
                                                postId: postId,
                                                postData: post,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Xem chi tiết',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Không xác định';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

