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

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Map để theo dõi trạng thái tải cho từng userId
  final Map<String, bool> _loadingUsers = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định người dùng hiện tại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể khóa chính mình!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loadingUsers[userId] = true; 
    });

    try {
      // Cập nhật trạng thái isBlocked trong Firestore
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Bạn không có quyền thực hiện hành động này.';
        print(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _loadingUsers.remove(userId); // Xóa trạng thái tải sau khi hoàn tất
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return AdminScaffold(
      title: 'Quản lý Người dùng',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                hintText: 'Nhập tên hoặc email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không có người dùng nào'));
                }

                final users =
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return UserModel.tryParse(data) ??
                          UserModel(
                            uid: doc.id,
                            name: 'Không xác định',
                            email: '',
                            avatarUrl: '',
                            coverUrl: '',
                            bio: '',
                            gender: 'Unknown',
                            createdAt: DateTime.now(),
                          );
                    }).toList();

                final filteredUsers =
                    users.where((user) {
                      final userName = user.name.toLowerCase();
                      final userEmail = user.email.toLowerCase();
                      return _searchQuery.isEmpty ||
                          userName.contains(_searchQuery) ||
                          userEmail.contains(_searchQuery);
                    }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy người dùng phù hợp'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isBlocked = user.isBlocked;
                    final isCurrentUser = currentUser?.uid == user.uid;
                    final isLoading = _loadingUsers[user.uid] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                          child:
                              user.avatarUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text(
                              isBlocked ? 'Đã khóa' : 'Đang hoạt động',
                              style: TextStyle(
                                color: isBlocked ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing:
                            isCurrentUser
                                ? const Text(
                                  'Bạn',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Switch(
                                  value: !isBlocked,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                  onChanged: (newValue) {
                                    _toggleUserStatus(user.uid, isBlocked);
                                  },
                                ),
                        onTap: () {
                          _showUserDetailsDialog(context, user);
                        },
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

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    final currentUser = _auth.currentUser;
    final isCurrentUser = currentUser?.uid == user.uid;
    final isLoading = _loadingUsers[user.uid] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thông tin chi tiết'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                    child:
                        user.avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('ID:', user.uid),
                _buildInfoRow('Tên:', user.name),
                _buildInfoRow('Email:', user.email),
                _buildInfoRow('Giới tính:', user.gender),
                _buildInfoRow(
                  'Tiểu sử:',
                  user.bio.isEmpty ? 'Không có' : user.bio,
                ),
                _buildInfoRow(
                  'Ngày tạo:',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                _buildInfoRow(
                  'Bạn bè:',
                  user.friends.isEmpty
                      ? 'Không có'
                      : user.friends.length.toString(),
                ),
                _buildInfoRow(
                  'Yêu cầu chờ:',
                  user.pendingRequests.isEmpty
                      ? 'Không có'
                      : user.pendingRequests.length.toString(),
                ),
                _buildInfoRow('Quản trị viên:', user.isAdmin ? 'Có' : 'Không'),
                _buildInfoRow(
                  'Trạng thái:',
                  user.isBlocked ? 'Đã khóa' : 'Đang hoạt động',
                  valueColor: user.isBlocked ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
            if (!isCurrentUser)
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: () {
                      _toggleUserStatus(user.uid, user.isBlocked);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          user.isBlocked ? Colors.green : Colors.red,
                    ),
                    child: Text(
                      user.isBlocked ? 'Mở khóa' : 'Khóa',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
