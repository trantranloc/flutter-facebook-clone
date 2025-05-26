// post_management_screen.dart - Phiên bản tối ưu
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
  final Map<String, String> _userNameCache = {}; // Cache tên user

  // Tối ưu: Cache tên user để tránh gọi API nhiều lần
  Future<String> _getCachedUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final userName = snapshot.data()?['name'] ?? 'Không xác định';
      _userNameCache[userId] = userName;
      return userName;
    } catch (e) {
      debugPrint('Lỗi khi lấy tên user $userId: $e');
      return 'Không xác định';
    }
  }

  // Tối ưu: Tạo PostData model để truyền dữ liệu rõ ràng hơn
  Map<String, dynamic> _createPostDetailData({
    required String postId,
    required Map<String, dynamic> postData,
    required int reportCount,
    required List<String> reportReasons,
    required List<Map<String, dynamic>> reports,
  }) {
    return {
      'postId': postId,
      'userId': postData['userId'],
      'userName': postData['userName'],
      'content': postData['content'],
      'createdAt': postData['createdAt'],
      'updatedAt': postData['updatedAt'],
      'reportCount': reportCount,
      'reportReasons': reportReasons,
      'reports': reports,
      'isReported': true, // Vì đây là bài viết bị báo cáo
    };
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý Bài viết',
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('reports')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, reportSnapshot) {
          if (reportSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportSnapshot.hasError) {
            debugPrint('Error loading reports: ${reportSnapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${reportSnapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (!reportSnapshot.hasData || reportSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có bài viết bị báo cáo',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Nhóm báo cáo theo postId
          final reportDocs = reportSnapshot.data!.docs;
          final Map<String, List<Map<String, dynamic>>> groupedReports = {};

          for (var doc in reportDocs) {
            final report = doc.data() as Map<String, dynamic>;
            final postId = report['postId'] as String;

            if (postId.isNotEmpty) {
              groupedReports.putIfAbsent(postId, () => []).add({
                ...report,
                'reportId': doc.id, // Thêm ID của report
              });
            }
          }

          if (groupedReports.isEmpty) {
            return const Center(
              child: Text('Không có bài viết hợp lệ để hiển thị'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedReports.length,
            itemBuilder: (context, index) {
              final postId = groupedReports.keys.elementAt(index);
              final reports = groupedReports[postId]!;
              final reportCount = reports.length;
              final isLoading = _loadingPosts[postId] ?? false;

              return _buildPostCard(
                postId: postId,
                reports: reports,
                reportCount: reportCount,
                isLoading: isLoading,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard({
    required String postId,
    required List<Map<String, dynamic>> reports,
    required int reportCount,
    required bool isLoading,
  }) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('posts').doc(postId).get(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 120,
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (postSnapshot.hasError) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Lỗi khi tải bài viết $postId',
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text(
                    '${postSnapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.delete_forever, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text('Bài viết đã bị xóa (ID: $postId)'),
                  Text(
                    'Báo cáo: $reportCount',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final postData = postSnapshot.data!.data() as Map<String, dynamic>;
        final reportReasons =
            reports
                .map((r) => r['reason']?.toString() ?? 'Không rõ')
                .where((reason) => reason.isNotEmpty)
                .toSet()
                .toList();

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
                // Header với thông tin user
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        (postData['userName']?.toString().isNotEmpty == true)
                            ? postData['userName']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: _getCachedUserName(
                              postData['userId']?.toString() ?? '',
                            ),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Đang tải...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                          Text(
                            _formatTimestamp(postData['createdAt']),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge số báo cáo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$reportCount báo cáo',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Nội dung bài viết
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    postData['content']?.toString() ?? 'Không có nội dung',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 12),

                // Lý do báo cáo
                if (reportReasons.isNotEmpty) ...[
                  const Text(
                    'Lý do báo cáo:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        reportReasons.map((reason) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Nút hành động
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed:
                            () => _navigateToPostDetail(
                              postId: postId,
                              postData: postData,
                              reports: reports,
                              reportCount: reportCount,
                              reportReasons: reportReasons,
                            ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Xem chi tiết'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
  }

  void _navigateToPostDetail({
    required String postId,
    required Map<String, dynamic> postData,
    required List<Map<String, dynamic>> reports,
    required int reportCount,
    required List<String> reportReasons,
  }) {
    // Tạo dữ liệu đầy đủ và có cấu trúc để truyền
    final detailData = _createPostDetailData(
      postId: postId,
      postData: postData,
      reportCount: reportCount,
      reportReasons: reportReasons,
      reports: reports,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostDetailScreen(postId: postId, postData: detailData),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Không xác định';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Không xác định';
      }

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Lỗi format timestamp: $e');
      return 'Không xác định';
    }
  }

  @override
  void dispose() {
    _userNameCache.clear();
    super.dispose();
  }
}
