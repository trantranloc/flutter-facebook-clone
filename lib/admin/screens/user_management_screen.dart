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
  final TextEditingController _banReasonController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, blocked, banned, admin
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
    _banReasonController.dispose();
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

  Future<void> _banUser(String userId, String reason, DateTime banUntil) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Không thể xác định người dùng hiện tại', Colors.red);
      return;
    }

    if (userId == currentUser.uid) {
      _showSnackBar('Bạn không thể ban chính mình!', Colors.orange);
      return;
    }

    setState(() {
      _loadingUsers[userId] = true;
    });

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedReason': reason,
        'bannedUntil': Timestamp.fromDate(banUntil),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ghi log hành động
      await _logAdminAction(
        action: 'ban_user',
        targetUserId: userId,
        description:
            'Ban người dùng đến ${_formatDate(banUntil)} - Lý do: $reason',
      );

      _showSnackBar('Đã ban người dùng thành công', Colors.green);
    } catch (e) {
      debugPrint('Lỗi ban user: $e');
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

  Future<void> _unbanUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Không thể xác định người dùng hiện tại', Colors.red);
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await _showConfirmDialog(
      title: 'Gỡ ban người dùng',
      content: 'Bạn có chắc chắn muốn gỡ ban cho người dùng này?',
      confirmText: 'Gỡ ban',
      isDestructive: false,
    );

    if (!confirmed) return;

    setState(() {
      _loadingUsers[userId] = true;
    });

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'bannedAt': FieldValue.delete(),
        'bannedReason': FieldValue.delete(),
        'bannedUntil': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ghi log hành động
      await _logAdminAction(
        action: 'unban_user',
        targetUserId: userId,
        description: 'Gỡ ban người dùng',
      );

      _showSnackBar('Đã gỡ ban người dùng thành công', Colors.green);
    } catch (e) {
      debugPrint('Lỗi unban user: $e');
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

  Future<void> _showBanDialog(String userId, String userName) async {
    int selectedDays = 7;
    final reasons = [
      'Vi phạm chính sách cộng đồng Vi phạm chính sách cộng đồng',
      'Spam hoặc nội dung rác',
      'Ngôn từ thù địch',
      'Nội dung không phù hợp',
      'Giả mạo danh tính',
      'Khác',
    ];
    String selectedReason = reasons.first;
    _banReasonController.clear();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text('Ban người dùng: $userName'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian ban:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedDays,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              [1, 3, 7, 14, 30, 90, 365]
                                  .map(
                                    (days) => DropdownMenuItem(
                                      value: days,
                                      child: Text('$days ngày'),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => selectedDays = value!),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Lý do ban:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedReason,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              reasons
                                  .map(
                                    (reason) => DropdownMenuItem(
                                      value: reason,
                                      child: Flexible(
                                        child: Text(
                                          reason,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          selectedItemBuilder: (context) {
                            return reasons.map((reason) {
                              return SizedBox(
                                width: 200,
                                child: Text(
                                  reason,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList();
                          },
                          onChanged:
                              (value) =>
                                  setState(() => selectedReason = value!),
                        ),
                        if (selectedReason == 'Khác') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _banReasonController,
                            decoration: const InputDecoration(
                              labelText: 'Nhập lý do cụ thể',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final reason =
                            selectedReason == 'Khác'
                                ? _banReasonController.text.trim()
                                : selectedReason;
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập lý do ban'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'days': selectedDays,
                          'reason': reason,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ban'),
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      final banUntil = DateTime.now().add(Duration(days: result['days']));
      await _banUser(userId, result['reason'], banUntil);
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
          matchesFilter = !user.isBlocked && !user.isBanned;
          break;
        case 'blocked':
          matchesFilter = user.isBlocked;
          break;
        case 'banned':
          matchesFilter = user.isBanned;
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

  bool _isBanExpired(UserModel user) {
    if (!user.isBanned || user.bannedUntil == null) return false;
    return DateTime.now().isAfter(user.bannedUntil!);
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
                _buildFilterChip('banned', 'Bị ban', Icons.gavel),
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
    final isBanned = user.isBanned;
    final isBanExpired = _isBanExpired(user);
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
                                  color:
                                      isBanned
                                          ? Colors.red.shade700
                                          : isBlocked
                                          ? Colors.orange
                                          : Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    isBanned
                                        ? Icon(
                                          Icons.gavel,
                                          size: 10,
                                          color: Colors.white,
                                        )
                                        : null,
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
                                          isBanned
                                              ? Colors.red.shade100
                                              : isBlocked
                                              ? Colors.orange.shade100
                                              : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isBanned
                                          ? (isBanExpired
                                              ? 'Ban hết hạn'
                                              : 'Đã ban')
                                          : isBlocked
                                          ? 'Đã khóa'
                                          : 'Hoạt động',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isBanned
                                                ? Colors.red.shade700
                                                : isBlocked
                                                ? Colors.orange.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isBanned && user.bannedUntil != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ban đến: ${_formatDate(user.bannedUntil!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action buttons
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBanned && !isBanExpired)
                                IconButton(
                                  icon: const Icon(
                                    Icons.restore,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _unbanUser(user.uid),
                                  tooltip: 'Gỡ ban',
                                )
                              else if (!isBanned)
                                IconButton(
                                  icon: const Icon(
                                    Icons.gavel,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _showBanDialog(user.uid, user.name),
                                  tooltip: 'Ban người dùng',
                                ),
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
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar and name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                          backgroundColor: Colors.grey.shade100,
                          child:
                              user.avatarUrl.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey.shade500,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // User details with card style
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'UID:',
                              user.uid,
                              Icons.fingerprint,
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Giới tính:',
                              user.gender,
                              Icons.person_outline,
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Số bạn bè:',
                              '${user.friends.length}',
                              Icons.group,
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Tham gia:',
                              _formatDate(user.createdAt),
                              Icons.calendar_today,
                            ),
                            if (user.bio.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                'Giới thiệu:',
                                user.bio,
                                Icons.info_outline,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Status section
                    const Text(
                      'Trạng thái:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(
                          'Admin',
                          user.isAdmin,
                          Colors.purple.shade400,
                        ),
                        _buildStatusChip(
                          'Bị khóa',
                          user.isBlocked,
                          Colors.orange.shade400,
                        ),
                        _buildStatusChip(
                          'Bị cấm',
                          user.isBanned,
                          Colors.red.shade400,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Cập nhật trạng thái isAdmin
                          final newAdminStatus = !user.isAdmin;
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'isAdmin': newAdminStatus});
// Tạo thông báo về phân quyền
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .add({
                                'action':
                                    newAdminStatus
                                        ? 'Bạn đã được cấp quyền quản trị viên.'
                                        : 'Quyền quản trị viên của bạn đã bị xóa.',
                                'isRead': false,
                                'senderAvatarUrl': 'assets/images/logos.png',
                                'senderName': 'Quản trị viên',
                                'timestamp': Timestamp.now(),
                                'type': 'admin_status',
                                'userId': user.uid,
                              });
                          // Cập nhật UI
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newAdminStatus
                                    ? 'Đã cấp quyền admin'
                                    : 'Đã xóa quyền admin',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi khi cập nhật quyền admin: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        user.isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.admin_panel_settings,
                        size: 20,
                      ),
                      label: Text(
                        user.isAdmin ? 'Xóa quyền Admin' : 'Cấp quyền Admin',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            user.isAdmin
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Ban information
                    if (user.isBanned) ...[
                      const SizedBox(height: 24),
                      Card(
                        elevation: 0,
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin ban:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (user.bannedReason != null)
                                _buildDetailRow(
                                  'Lý do:',
                                  user.bannedReason!,
                                  Icons.warning_amber,
                                ),
                              if (user.bannedUntil != null)
                                _buildDetailRow(
                                  'Ban đến:',
                                  _formatDate(user.bannedUntil!),
                                  Icons.timer,
                                ),
                              if (user.bannedAt != null)
                                _buildDetailRow(
                                  'Bị ban lúc:',
                                  _formatDate(user.bannedAt!),
                                  Icons.history,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Cập nhật hàm _buildDetailRow để thêm icon
  Widget _buildDetailRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // Cập nhật hàm _buildStatusChip để cải thiện giao diện
  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isActive ? color : Colors.grey.shade200,
      side: BorderSide(color: isActive ? color : Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
