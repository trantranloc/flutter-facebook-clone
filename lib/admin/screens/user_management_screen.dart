import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_scaffold.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, blocked, admin
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _loadingUsers = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Không thể xác định người dùng hiện tại', Colors.red);
      return;
    }

    if (userId == currentUser.uid) {
      _showSnackBar('Bạn không thể khóa chính mình!', Colors.orange);
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await _showConfirmDialog(
      title: currentStatus ? 'Mở khóa người dùng' : 'Khóa người dùng',
      content:
          currentStatus
              ? 'Bạn có chắc chắn muốn mở khóa người dùng này?'
              : 'Bạn có chắc chắn muốn khóa người dùng này? Họ sẽ không thể truy cập ứng dụng.',
      confirmText: currentStatus ? 'Mở khóa' : 'Khóa',
      isDestructive: !currentStatus,
    );

    if (!confirmed) return;

    setState(() {
      _loadingUsers[userId] = true;
    });

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ghi log hành động
      await _logAdminAction(
        action: currentStatus ? 'unblock_user' : 'block_user',
        targetUserId: userId,
        description: currentStatus ? 'Mở khóa người dùng' : 'Khóa người dùng',
      );

      _showSnackBar(
        currentStatus
            ? 'Đã mở khóa người dùng thành công'
            : 'Đã khóa người dùng thành công',
        Colors.green,
      );
    } catch (e) {
      debugPrint('Lỗi toggle user status: $e');
      String errorMessage = 'Có lỗi xảy ra';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Bạn không có quyền thực hiện hành động này';
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loadingUsers.remove(userId);
        });
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _logAdminAction({
    required String action,
    required String targetUserId,
    required String description,
  }) async {
    try {
      await _firestore.collection('admin_logs').add({
        'action': action,
        'adminId': _auth.currentUser?.uid ?? 'unknown',
        'targetUserId': targetUserId,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Lỗi ghi log: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      // Tìm kiếm theo tên/email
      final matchesSearch =
          _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);

      // Lọc theo trạng thái
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'active':
          matchesFilter = !user.isBlocked;
          break;
        case 'blocked':
          matchesFilter = user.isBlocked;
          break;
        case 'admin':
          matchesFilter = user.isAdmin;
          break;
        case 'all':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return AdminScaffold(
      title: 'Quản lý Người dùng',
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilterSection(),
            Expanded(child: _buildUsersList(currentUser)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                hintText: 'Nhập tên hoặc email...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả', Icons.people),
                _buildFilterChip('active', 'Hoạt động', Icons.check_circle),
                _buildFilterChip('blocked', 'Bị khóa', Icons.block),
                _buildFilterChip(
                  'admin',
                  'Quản trị',
                  Icons.admin_panel_settings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.blue.shade600,
        checkmarkColor: Colors.white,
        elevation: isSelected ? 4 : 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildUsersList(User? currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Lỗi tải dữ liệu: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return _buildLoadingWidget();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget('Không có người dùng nào trong hệ thống');
        }

        final users =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return UserModel.tryParse(data) ??
                  UserModel(
                    uid: doc.id,
                    name: 'Không xác định',
                    email: data['email'] ?? '',
                    avatarUrl: data['avatarUrl'] ?? '',
                    coverUrl: data['coverUrl'] ?? '',
                    bio: data['bio'] ?? '',
                    gender: data['gender'] ?? 'Unknown',
                    createdAt: DateTime.now(),
                  );
            }).toList();

        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return _buildEmptyWidget('Không tìm thấy người dùng phù hợp');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _buildUserCard(user, currentUser);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, User? currentUser) {
    final isBlocked = user.isBlocked;
    final isCurrentUser = currentUser?.uid == user.uid;
    final isLoading = _loadingUsers[user.uid] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border:
                    isCurrentUser
                        ? Border.all(color: Colors.blue.shade300, width: 2)
                        : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUserDetailsDialog(context, user),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar với status indicator
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  user.avatarUrl.isNotEmpty
                                      ? NetworkImage(user.avatarUrl)
                                      : null,
                              backgroundColor: Colors.grey.shade200,
                              child:
                                  user.avatarUrl.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: 32,
                                        color: Colors.grey.shade600,
                                      )
                                      : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isBlocked ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.isAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isBlocked
                                              ? Colors.red.shade100
                                              : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isBlocked ? 'Đã khóa' : 'Hoạt động',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isBlocked
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${user.friends.length} bạn bè',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action button
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Bạn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          )
                        else if (isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Switch(
                            value: !isBlocked,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            onChanged: (newValue) {
                              _toggleUserStatus(user.uid, isBlocked);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải danh sách người dùng...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    final currentUser = _auth.currentUser;
    final isCurrentUser = currentUser?.uid == user.uid;
    final isLoading = _loadingUsers[user.uid] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                user.avatarUrl.isNotEmpty
                                    ? NetworkImage(user.avatarUrl)
                                    : null,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child:
                                user.avatarUrl.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          if (user.isAdmin)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.fingerprint,
                          label: 'ID người dùng',
                          value: user.uid,
                          isMonospace: true,
                        ),
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Giới tính',
                          value: _getGenderText(user.gender),
                        ),
                        _buildDetailRow(
                          icon: Icons.info_outline,
                          label: 'Tiểu sử',
                          value:
                              user.bio.isEmpty ? 'Chưa có tiểu sử' : user.bio,
                        ),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Ngày tham gia',
                          value: _formatDate(user.createdAt),
                        ),
                        _buildDetailRow(
                          icon: Icons.people,
                          label: 'Số bạn bè',
                          value: user.friends.length.toString(),
                        ),
                        _buildDetailRow(
                          icon: Icons.pending_actions,
                          label: 'Lời mời chờ',
                          value: user.pendingRequests.length.toString(),
                        ),
                        _buildDetailRow(
                          icon:
                              user.isBlocked ? Icons.block : Icons.check_circle,
                          label: 'Trạng thái',
                          value:
                              user.isBlocked ? 'Đã bị khóa' : 'Đang hoạt động',
                          valueColor:
                              user.isBlocked ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                      if (!isCurrentUser) ...[
                        const SizedBox(width: 12),
                        if (isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleUserStatus(user.uid, user.isBlocked);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  user.isBlocked ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(user.isBlocked ? 'Mở khóa' : 'Khóa'),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
