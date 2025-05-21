// Màn hình chi tiết bài viết
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_scaffold.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Hàm xử lý hành động trên bài viết
  Future<void> _handlePostAction(String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (action) {
        case 'ignore':
          await _firestore.collection('posts').doc(widget.postId).update({
            'isReported': false,
            'reportCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await _logAdminAction(
            'ignore_report',
            widget.postId,
            'Bỏ qua báo cáo',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã bỏ qua báo cáo'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pop(context);
          break;
        case 'delete':
          await _firestore.collection('posts').doc(widget.postId).delete();
          await _logAdminAction('delete_post', widget.postId, 'Xóa bài viết');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa bài viết'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          break;
        case 'warn':
          await _firestore.collection('notifications').add({
            'userId': widget.postData['userId'],
            'message':
                'Bài viết của bạn đã bị báo cáo do vi phạm chính sách. Vui lòng kiểm tra lại nội dung.',
            'type': 'warning',
            'timestamp': FieldValue.serverTimestamp(),
          });
          await _firestore.collection('posts').doc(widget.postId).update({
            'isReported': false,
            'reportCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await _logAdminAction(
            'warn_user',
            widget.postId,
            'Cảnh báo người dùng',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi cảnh báo đến người dùng'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
          break;
        case 'ban':
          await _firestore
              .collection('users')
              .doc(widget.postData['userId'])
              .update({
                'isBanned': true,
                'bannedUntil': Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 7)),
                ),
              });
          await _firestore.collection('posts').doc(widget.postId).delete();
          await _firestore.collection('notifications').add({
            'userId': widget.postData['userId'],
            'message': 'Tài khoản của bạn đã bị cấm do vi phạm chính sách.',
            'type': 'ban',
            'timestamp': FieldValue.serverTimestamp(),
          });
          await _logAdminAction(
            'ban_user',
            widget.postId,
            'Cấm tài khoản người dùng',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cấm tài khoản và xóa bài viết'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
          break;
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
        _isLoading = false;
      });
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
      title: 'Chi tiết Bài viết',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin bài viết
            Card(
              elevation: 4,
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
                            widget.postData['userName']?.substring(0, 1) ?? 'U',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.postData['userName'] ?? 'Không xác định',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatTimestamp(widget.postData['createdAt']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nội dung bài viết:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.postData['content'] ?? 'Không có nội dung'),
                    const SizedBox(height: 8),
                    Text(
                      'Số báo cáo: ${widget.postData['reportCount'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Danh sách báo cáo
            const Text(
              'Danh sách báo cáo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('reports')
                      .where('postId', isEqualTo: widget.postId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Không có báo cáo nào.');
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report =
                        reports[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('Người báo cáo: ${report['reportedBy']}'),
                        subtitle: Text('Lý do: ${report['reason']}'),
                        trailing: Text(_formatTimestamp(report['timestamp'])),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Nút hành động
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _handlePostAction('ignore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Bỏ qua'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handlePostAction('delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Xóa'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handlePostAction('warn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Cảnh báo'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handlePostAction('ban'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Cấm'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Không xác định';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
