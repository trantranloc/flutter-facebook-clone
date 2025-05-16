import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/screens/group/group_screen.dart';
import 'package:flutter_facebook_clone/models/group.dart';
import 'package:flutter_facebook_clone/screens/group/manage_group_screen.dart';

class GroupHomeScreen extends StatefulWidget {
  final String groupId;

  const GroupHomeScreen({super.key, required this.groupId});

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Group? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final doc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (doc.exists) {
        setState(() {
          _group = Group.fromMap(doc.data()!, doc.id);
          _isLoading = false;
        });
      } else {
        throw Exception('Nhóm không tồn tại');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Hàm xóa nhóm
  Future<void> _deleteGroup() async {
    try {
      // Xóa tài liệu nhóm từ Firestore
      await _firestore.collection('groups').doc(widget.groupId).delete();
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa nhóm thành công')));
      // Điều hướng về GroupScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GroupScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa nhóm: $e')));
    }
  }

  // Hiển thị hộp thoại xác nhận xóa nhóm
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Không cho phép đóng dialog bằng cách nhấn ra ngoài
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa nhóm'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa nhóm này? Hành động này không thể hoàn tác.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng dialog
                await _deleteGroup(); // Thực hiện xóa nhóm
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GroupScreen()),
            );
          },
        ),
        title:
            _isLoading
                ? const Text('Nhóm')
                : Text(
                  _group?.name ?? 'Nhóm',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: Thêm logic tìm kiếm
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Thêm logic chỉnh sửa nhóm
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog(); // Hiển thị dialog xác nhận xóa
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Chỉnh sửa'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Xóa nhóm',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            _group?.coverImageUrl.isNotEmpty ?? false
                                ? _group!.coverImageUrl
                                : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Thêm logic chỉnh sửa ảnh bìa
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('CHỈNH SỬA'),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _group?.name ?? 'Nhóm',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _group?.privacy == 'Công khai'
                                ? 'Nhóm Công khai • >1 thành viên'
                                : 'Nhóm Riêng tư • >1 thành viên',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Thêm logic mời thành viên
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Mời'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageGroupScreen(groupId: widget.groupId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Quản lý'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Thêm logic sửa kiển
                            },
                            icon: const Icon(Icons.star),
                            label: const Text('Sửa kiên'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              FirebaseAuth.instance.currentUser?.photoURL ??
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Bạn viết gì...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo),
                            onPressed: () {
                              // TODO: Thêm logic chọn ảnh
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildOption(
                            Icons.edit,
                            'Bài viết ảnh đành',
                            Colors.green,
                          ),
                          _buildOption(
                            Icons.camera_alt,
                            'Cảm xúc',
                            Colors.yellow,
                          ),
                          _buildOption(Icons.video_call, 'Thăm dò', Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hãy hoàn tất quy trình thiết lập nhóm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Thêm logic đóng thông báo
                            },
                            child: const Text('X'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Tiếp tục thêm các thông tin chi tiết để nhóm của bạn nổi bật trong cộng đồng này.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildActionChip(
                            'Mời người tham gia',
                            Icons.person_add,
                          ),
                          _buildActionChip('Thêm ảnh bìa', Icons.image),
                          _buildActionChip(
                            'Thêm phần mô tả',
                            Icons.description,
                          ),
                          _buildActionChip('Tạo bài viết', Icons.create),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      onPressed: () {
        // TODO: Thêm logic cho từng hành động
      },
      backgroundColor: Colors.grey[200],
    );
  }
}
