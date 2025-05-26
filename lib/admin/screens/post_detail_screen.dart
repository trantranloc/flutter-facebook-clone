// post_detail_screen.dart - Phiên bản tối ưu
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
  late Map<String, dynamic> _currentPostData;
  String? _cachedUserName;

  @override
  void initState() {
    super.initState();
    _currentPostData = Map<String, dynamic>.from(widget.postData);
    _loadUserName();
  }

  // Cache tên user để tránh gọi API nhiều lần
  Future<void> _loadUserName() async {
    if (_cachedUserName != null) return;

    try {
      final userId = _currentPostData['userId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        final snapshot = await _firestore.collection('users').doc(userId).get();
        if (mounted) {
          setState(() {
            _cachedUserName =
                snapshot.data()?['name'] ??
                snapshot.data()?['userName'] ??
                'Không xác định';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải tên user: $e');
      if (mounted) {
        setState(() {
          _cachedUserName = 'Không xác định';
        });
      }
    }
  }

  Future<String> _getUserName(String? userId) async {
    if (userId == null || userId.isEmpty) return 'Ẩn danh';
    try {
      var doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      return doc.exists ? doc.get('displayName') ?? 'Ẩn danh' : 'Ẩn danh';
    } catch (e) {
      return 'Ẩn danh';
    }
  }

  // Hàm xử lý hành động trên bài viết - Tối ưu với better error handling
  Future<void> _handlePostAction(String action) async {
    if (_isLoading) return; // Tránh spam click

    // Xác nhận hành động nguy hiểm
    if (action == 'delete' || action == 'ban') {
      final confirmed = await _showConfirmationDialog(action);
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _currentPostData['userId']?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('Không tìm thấy ID người dùng');
      }

      switch (action) {
        case 'ignore':
          await _handleIgnoreAction();
          break;
        case 'delete':
          await _handleDeleteAction();
          break;
        case 'warn':
          await _handleWarnAction(userId);
          break;
        case 'ban':
          await _handleBanAction(userId);
          break;
        default:
          throw Exception('Hành động không hợp lệ: $action');
      }

      // Cập nhật UI state
      if (mounted) {
        _showSuccessMessage(_getSuccessMessage(action));

        // Delay để user thấy thông báo rồi mới pop
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, true); // Trả về true để refresh parent
        }
      }
    } catch (e) {
      debugPrint('Lỗi xử lý hành động $action: $e');
      if (mounted) {
        _showErrorMessage(_getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog(String action) async {
    final actionText = _getActionText(action);
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận $actionText'),
            content: Text(
              'Bạn có chắc chắn muốn $actionText bài viết này? '
              'Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'ban' ? Colors.red : Colors.orange,
                ),
                child: Text('Xác nhận $actionText'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  String _getActionText(String action) {
    switch (action) {
      case 'delete':
        return 'xóa';
      case 'ban':
        return 'cấm';
      case 'warn':
        return 'cảnh báo';
      case 'ignore':
        return 'bỏ qua';
      default:
        return action;
    }
  }

  String _getSuccessMessage(String action) {
    switch (action) {
      case 'ignore':
        return 'Đã bỏ qua báo cáo thành công';
      case 'delete':
        return 'Đã xóa bài viết thành công';
      case 'warn':
        return 'Đã gửi cảnh báo đến người dùng';
      case 'ban':
        return 'Đã cấm tài khoản và xóa bài viết';
      default:
        return 'Đã thực hiện hành động thành công';
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission-denied')) {
      return 'Bạn không có quyền thực hiện hành động này';
    } else if (errorStr.contains('not-found')) {
      return 'Không tìm thấy dữ liệu cần thiết';
    } else if (errorStr.contains('network')) {
      return 'Lỗi kết nối mạng. Vui lòng thử lại';
    } else {
      return 'Có lỗi xảy ra: ${error.toString()}';
    }
  }

  // Các hàm xử lý hành động cụ thể
  Future<void> _handleIgnoreAction() async {
    await _firestore.collection('posts').doc(widget.postId).update({
      'isReported': false,
      'reportCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Xóa tất cả báo cáo liên quan
    final reportQuery =
        await _firestore
            .collection('reports')
            .where('postId', isEqualTo: widget.postId)
            .get();

    final batch = _firestore.batch();
    for (var doc in reportQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _logAdminAction('ignore_report', 'Bỏ qua báo cáo');
  }

  Future<void> _handleDeleteAction() async {
    // Xóa bài viết
    await _firestore.collection('posts').doc(widget.postId).delete();

    // Xóa các báo cáo liên quan
    final reportQuery =
        await _firestore
            .collection('reports')
            .where('postId', isEqualTo: widget.postId)
            .get();

    final batch = _firestore.batch();
    for (var doc in reportQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _logAdminAction('delete_post', 'Xóa bài viết');
  }

  Future<void> _handleWarnAction(String userId) async {
    // Gửi thông báo cảnh báo
    await _firestore.collection('notifications').add({
      'userId': userId,
      'senderName': 'Quản trị viên',
      'senderAvatarUrl': "assets/images/logos.png",
      'action':
          'Bài viết của bạn đã bị báo cáo do vi phạm chính sách cộng đồng. '
          'Vui lòng đọc kỹ quy định và tuân thủ để tránh bị xử lý nặng hơn.',
      'type': 'warning',
      'postId': widget.postId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Reset trạng thái báo cáo
    await _firestore.collection('posts').doc(widget.postId).update({
      'isReported': false,
      'reportCount': 0,
      'isWarned': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Xóa báo cáo
    await _clearReports();
    await _logAdminAction('warn_user', 'Cảnh báo người dùng');
  }

  Future<void> _handleBanAction(String userId) async {
    final batch = _firestore.batch();

    // Cấm user
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'isBanned': true,
      'bannedUntil': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'bannedReason': 'Vi phạm chính sách cộng đồng',
      'bannedAt': FieldValue.serverTimestamp(),
    });

    // Xóa bài viết
    final postRef = _firestore.collection('posts').doc(widget.postId);
    batch.delete(postRef);

    await batch.commit();

    // Gửi thông báo
    await _firestore.collection('notifications').add({
      'userId': userId,
      'message':
          'Tài khoản của bạn đã bị cấm 7 ngày do vi phạm nghiêm trọng chính sách cộng đồng.',
      'type': 'ban',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _clearReports();
    await _logAdminAction('ban_user', 'Cấm tài khoản người dùng');
  }

  Future<void> _clearReports() async {
    final reportQuery =
        await _firestore
            .collection('reports')
            .where('postId', isEqualTo: widget.postId)
            .get();

    final batch = _firestore.batch();
    for (var doc in reportQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Ghi log hành động admin - Cải thiện
  Future<void> _logAdminAction(String action, String description) async {
    try {
      await _firestore.collection('admin_logs').add({
        'action': action,
        'postId': widget.postId,
        'adminId': 'admin_user_id',
        'description': description,
        'postContent':
            _currentPostData['content']?.toString().substring(0, 100) ?? '',
        'targetUserId': _currentPostData['userId'],
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'reportCount': _currentPostData['reportCount'] ?? 0,
          'reportReasons': _currentPostData['reportReasons'] ?? [],
        },
      });
    } catch (e) {
      debugPrint('Lỗi khi ghi log admin: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // Có thể return data để refresh parent screen
      },
      child: AdminScaffold(
        title: 'Chi tiết Bài viết',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostInfoCard(),
              const SizedBox(height: 16),
              _buildReportsSection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfoCard() {
    final reportCount = _currentPostData['reportCount'] ?? 0;
    final content =
        _currentPostData['content']?.toString() ?? 'Không có nội dung';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với thông tin user và badge
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (_cachedUserName?.isNotEmpty == true)
                        ? _cachedUserName!.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cachedUserName ?? 'Đang tải...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(_currentPostData['createdAt']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.report, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '$reportCount',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nội dung bài viết
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.article,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nội dung bài viết:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    final reports = _currentPostData['reports'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Danh sách báo cáo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Chip(
                  label: Text('${reports.length} báo cáo'),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(color: Colors.orange.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (reports.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.report_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Không có báo cáo nào',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final report = reports[index] as Map<String, dynamic>;
                  return _buildReportItem(report, index + 1);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade100,
                radius: 16,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getUserName(report['reportedBy']),
                      builder:
                          (context, snapshot) => Text(
                            'Người báo cáo: ${snapshot.data ?? 'Đang tải...'}',
                            style: TextStyle(fontSize: 16),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report['reason']?.toString() ?? 'Không rõ lý do',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimestamp(report['timestamp']),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động xử lý',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang xử lý...'),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'ignore',
                          'Bỏ qua',
                          Icons.visibility_off,
                          Colors.blue,
                          'Bỏ qua báo cáo này',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'warn',
                          'Cảnh báo',
                          Icons.warning,
                          Colors.orange,
                          'Gửi cảnh báo cho user',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'delete',
                          'Xóa bài viết',
                          Icons.delete,
                          Colors.red,
                          'Xóa bài viết vĩnh viễn',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'ban',
                          'Cấm user',
                          Icons.block,
                          Colors.purple,
                          'Cấm user 7 ngày',
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
  }

  Widget _buildActionButton(
    String action,
    String label,
    IconData icon,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: () => _handlePostAction(action),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
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

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      debugPrint('Lỗi format timestamp: $e');
      return 'Không xác định';
    }
  }
}
