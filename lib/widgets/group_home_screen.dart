import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/screens/group_screen.dart';
import 'package:flutter_facebook_clone/models/group.dart';
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
      final doc = await _firestore.collection('groups').doc(widget.groupId).get();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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
        title: _isLoading
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
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Chỉnh sửa'),
              ),
            ],
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: _isLoading
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
                        _buildOption(Icons.edit, 'Bài viết ảnh đành', Colors.green),
                        _buildOption(Icons.camera_alt, 'Cảm xúc', Colors.yellow),
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
                        _buildActionChip('Mời người tham gia', Icons.person_add),
                        _buildActionChip('Thêm ảnh bìa', Icons.image),
                        _buildActionChip('Thêm phần mô tả', Icons.description),
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
      },
      backgroundColor: Colors.grey[200],
    );
  }
}