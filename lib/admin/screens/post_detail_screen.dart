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
  int? _userReportScore;

  @override
  void initState() {
    super.initState();
    _currentPostData = Map<String, dynamic>.from(widget.postData);
    _loadUserName();
    _loadUserReportScore();
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
      return doc.exists ? doc.get('name') ?? 'Ẩn danh' : 'Ẩn danh';
    } catch (e) {
      return 'Ẩn danh';
    }
  }

  Future<void> _loadUserReportScore() async {
    try {
      final userId = _currentPostData['userId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        final snapshot = await _firestore.collection('users').doc(userId).get();
        if (mounted) {
          setState(() {
            _userReportScore = snapshot.data()?['reportScore'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải reportScore: $e');
      if (mounted) {
        setState(() {
          _userReportScore = 0;
        });
      }
    }
  }

  Future<List<String>> _getImagePost(String? postId) async {
    if (postId == null || postId.isEmpty) {
      return [];
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get();
      if (!doc.exists) {
        return [];
      }
      final imageUrls = doc.get('imageUrls');
      if (imageUrls is List && imageUrls.every((item) => item is String)) {
        return List<String>.from(imageUrls);
      }
      return [];
    } catch (e) {
      print('Error fetching image post: $e');
      return [];
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

  Future<void> _handleIgnoreAction() async {
    try {
      // Lấy thông tin user để cập nhật reportScore
      final userId = _currentPostData['userId']?.toString();
      final currentReportCount = _currentPostData['reportCount'] ?? 0;

      if (userId != null && userId.isNotEmpty && currentReportCount > 0) {
        // Lấy reportScore hiện tại của user
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final currentReportScore = userDoc.data()?['reportScore'] ?? 0;

        // Tính toán reportScore mới (trừ đi số report của bài viết khi bỏ qua)
        final newReportScore =
            (currentReportScore - currentReportCount)
                .clamp(0, double.infinity)
                .toInt();

        // Cập nhật reportScore của user
        await _firestore.collection('users').doc(userId).update({
          'reportScore': newReportScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _userReportScore = newReportScore;
          });
        }
      }

      // Reset trạng thái báo cáo của bài viết
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

      await _logAdminAction(
        'ignore_report',
        'Bỏ qua báo cáo - Trừ $currentReportCount điểm reportScore của user',
      );
    } catch (e) {
      debugPrint('Lỗi khi bỏ qua báo cáo: $e');
      rethrow;
    }
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
    final content =
        _currentPostData['content']?.toString() ?? 'Không có nội dung';
    print(_currentPostData);

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
                Tooltip(
                  message:
                      'Tổng số lần người dùng bị báo cáo vì vi phạm nội dung trên hệ thống',
                  preferBelow: true,
                  margin: const EdgeInsets.only(left: 80, right: 16),
                  textStyle: const TextStyle(
                    fontSize: 14, // Cỡ chữ của tooltip
                    color: Colors.white, // Màu chữ của tooltip
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 40, // Chiều cao của tooltip
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ), // Pa
                  child: Container(
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
                        Icon(
                          Icons.report,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_userReportScore ?? 0}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

                  // Hiển thị ảnh nếu có
                  FutureBuilder<List<String>>(
                    future: _getImagePost(widget.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          children: [
                            SizedBox(height: 16),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
                        return const Column(
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'Không thể tải hình ảnh',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        );
                      }
                      final imageUrls = snapshot.data ?? [];
                      if (imageUrls.isNotEmpty) {
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildImageSection(imageUrls),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        if (imageUrls.length == 1)
          // Hiển thị 1 ảnh
          _buildSingleImage(imageUrls[0])
        else if (imageUrls.length == 2)
          // Hiển thị 2 ảnh
          _buildTwoImages(imageUrls)
        else if (imageUrls.length == 3)
          // Hiển thị 3 ảnh
          _buildThreeImages(imageUrls)
        else
          // Hiển thị 4+ ảnh
          _buildMultipleImages(imageUrls),
      ],
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showImageDialog(imageUrl),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không thể tải ảnh',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<dynamic> imageUrls) {
    return Row(
      children: [
        Expanded(child: _buildImageThumbnail(imageUrls[0], height: 200)),
        const SizedBox(width: 8),
        Expanded(child: _buildImageThumbnail(imageUrls[1], height: 200)),
      ],
    );
  }

  Widget _buildThreeImages(List<dynamic> imageUrls) {
    return Column(
      children: [
        _buildImageThumbnail(imageUrls[0], height: 200),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildImageThumbnail(imageUrls[1], height: 150)),
            const SizedBox(width: 8),
            Expanded(child: _buildImageThumbnail(imageUrls[2], height: 150)),
          ],
        ),
      ],
    );
  }

  Widget _buildMultipleImages(List<dynamic> imageUrls) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildImageThumbnail(imageUrls[0], height: 150)),
            const SizedBox(width: 8),
            Expanded(child: _buildImageThumbnail(imageUrls[1], height: 150)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildImageThumbnail(imageUrls[2], height: 150)),
            const SizedBox(width: 8),
            Expanded(
              child:
                  imageUrls.length > 4
                      ? _buildMoreImagesOverlay(
                        imageUrls[3],
                        imageUrls.length - 4,
                      )
                      : _buildImageThumbnail(imageUrls[3], height: 150),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String imageUrl, {required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showImageDialog(imageUrl),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.broken_image,
                size: 32,
                color: Colors.grey.shade500,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreImagesOverlay(String imageUrl, int remainingCount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showAllImagesDialog(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.broken_image,
                    size: 32,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 16),
                            const Text('Không thể tải ảnh'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showAllImagesDialog() {
    final imageUrls = _currentPostData['imageUrls'] ?? [];

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black87,
            child: Column(
              children: [
                AppBar(
                  title: Text('Tất cả hình ảnh (${imageUrls.length})'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showImageDialog(imageUrls[index]);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade500,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
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
