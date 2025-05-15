import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/admin/admin_scaffold.dart';
class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _loadingPosts = {};

  Future<void> _handlePostAction(String postId, bool delete) async {
    setState(() {
      _loadingPosts[postId] = true;
    });

    try {
      if (delete) {
        // Xóa bài viết
        await _firestore.collection('posts').doc(postId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bài viết'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Bỏ qua báo cáo (đặt isReported về false)
        await _firestore.collection('posts').doc(postId).update({
          'isReported': false,
          'reportCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ qua báo cáo'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Bạn không có quyền thực hiện hành động này.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _loadingPosts.remove(postId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý Bài viết',
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('posts')
                .where('isReported', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có bài viết bị báo cáo'));
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          isLoading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _handlePostAction(postId, false);
                                    },
                                    child: const Text(
                                      'Bỏ qua',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _handlePostAction(postId, true);
                                    },
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
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
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Không xác định';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
