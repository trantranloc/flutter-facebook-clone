import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/invite_friends_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/manage_group_screen.dart';
import 'package:flutter_facebook_clone/models/group.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class GroupHomeScreen extends StatefulWidget {
  final String groupId;

  const GroupHomeScreen({super.key, required this.groupId});

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );
  Group? _group;
  bool _isLoading = true;
  String? _errorMessage;

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
        _errorMessage = 'Lỗi: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'Ảnh bìa quá lớn, vui lòng chọn ảnh dưới 5MB';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'group_covers',
          publicId: 'group_cover_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      final newCoverUrl = response.secureUrl;
      await _firestore.collection('groups').doc(widget.groupId).update({
        'coverImageUrl': newCoverUrl,
      });

      await _loadGroupData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh bìa thành công')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi cập nhật ảnh bìa: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật ảnh bìa: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGroup() async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa nhóm thành công')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GroupScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa nhóm: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteGroup();
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
            onPressed: () {
              // TODO: Thêm logic tìm kiếm
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Thêm logic chỉnh sửa nhóm
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndUploadCoverImage,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('CHỈNH SỬA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
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
                              ? 'Nhóm Công khai • ${_group?.members.length} thành viên'
                              : 'Nhóm Riêng tư • ${_group?.members.length} thành viên',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (_group?.description.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(
                            _group!.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading || _group == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InviteFriendsScreen(
                                        groupId: widget.groupId,
                                        group: _group!,
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Mời bạn bè', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ManageGroupScreen(groupId: widget.groupId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Quản lý', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Thêm logic sự kiện
                          },
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Sự kiện', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 5, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            _auth.currentUser?.photoURL ??
                                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Bạn viết gì đi...',
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
                          'Bài viết ẩn danh',
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
                  const Divider(height: 2, color: Colors.grey),
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
}