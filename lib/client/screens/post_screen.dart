import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostScreen extends StatefulWidget {
  final String postId;

  const PostScreen({super.key, required this.postId});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? postData;
  List<Map<String, dynamic>> _comments = [];
  bool isLoading = true;
  bool isCommentLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPost();
    _loadComments();
  }

  Future<void> _fetchPost() async {
    try {
      final postDoc = await _firestore.collection('posts').doc(widget.postId).get();
      if (postDoc.exists) {
        setState(() {
          postData = postDoc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài viết không tồn tại')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải bài viết: $e')),
      );
    }
  }

  Future<void> _loadComments() async {
    try {
      final commentDocs = await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('time', descending: true)
          .get();
      setState(() {
        _comments = commentDocs.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        isCommentLoading = false;
      });
    } catch (e) {
      setState(() {
        isCommentLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải bình luận: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  Widget _buildCommentItem(int index) {
    final comment = _comments[index];
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: comment['avatarUrl'] != null && comment['avatarUrl'].toString().isNotEmpty
            ? NetworkImage(comment['avatarUrl'])
            : null,
        backgroundColor: Colors.grey[300],
        child: (comment['avatarUrl'] == null || comment['avatarUrl'].toString().isEmpty)
            ? const Icon(Icons.person, size: 20)
            : null,
      ),
      title: Row(
        children: [
          Text(
            comment['name'] ?? 'Người dùng',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (comment['isAuthor'] == true) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tác giả',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
          if (comment['topComment'] == true) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Top bình luận',
                style: TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment['text'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTimestamp(comment['time']),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : postData == null
              ? const Center(child: Text('Không tìm thấy bài viết'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Ảnh đại diện, tên người đăng, thời gian
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                postData!['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1',
                              ),
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  postData!['name'] ?? 'Người dùng',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(postData!['createdAt']),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Nội dung bài viết
                      if (postData!['content'] != null && postData!['content'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            postData!['content'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Ảnh bài viết (nếu có)
                      if (postData!['imageUrls'] != null && (postData!['imageUrls'] as List).isNotEmpty)
                        Column(
                          children: (postData!['imageUrls'] as List).map((imageUrl) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red, size: 48),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      const Divider(),
                      // Phần bình luận
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: const Text(
                          'Bình luận',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      isCommentLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _comments.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Chưa có bình luận nào'),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) => _buildCommentItem(index),
                                ),
                    ],
                  ),
                ),
    );
  }
}