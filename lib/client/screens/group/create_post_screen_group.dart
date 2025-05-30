import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class CreatePostScreenGroup extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CreatePostScreenGroup({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CreatePostScreenGroup> createState() => _CreatePostScreenGroupState();
}

class _CreatePostScreenGroupState extends State<CreatePostScreenGroup> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  File? _postImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userAvatarUrl;
  String? _userName;
  Color _selectedBackgroundColor = Colors.white;

  // Initialize Cloudinary
  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // Load user data (avatar and name) from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userAvatarUrl = userDoc.data()?['avatarUrl']?.toString() ?? '';
            _userName = userDoc.data()?['name']?.toString() ?? 'Người dùng ẩn danh';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin người dùng: $e';
      });
    }
  }

  // Pick post image from gallery
  Future<void> _pickPostImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Ảnh quá lớn, vui lòng chọn ảnh dưới 5MB';
          });
          return;
        }
        setState(() {
          _postImage = imageFile;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Không có ảnh nào được chọn';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh: $e';
      });
    }
  }

  // Upload post image to Cloudinary
  Future<String> _uploadPostImageToCloudinary() async {
    if (_postImage == null) return '';
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _postImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'group_posts',
          publicId: 'post_image_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Lỗi khi tải ảnh lên: $e');
    }
  }

  // Save post to Firestore
  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập');

      final imageUrl = await _uploadPostImageToCloudinary();

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .add({
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'backgroundColor': _selectedBackgroundColor.value,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'groupId': widget.groupId,
        'likes': [],
        'comments': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài viết thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi đăng bài viết: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Select background color
  void _selectBackgroundColor(Color color) {
    setState(() {
      _selectedBackgroundColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWhiteBackground = _selectedBackgroundColor == Colors.white;
    final textColor = isWhiteBackground ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                  ? NetworkImage(_userAvatarUrl!)
                  : null,
              child: _userAvatarUrl == null || _userAvatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              _userName ?? 'Đang tải...',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _isLoading ? null : _savePost,
              child: const Text(
                'Đăng',
                style: TextStyle(
                  color: Color(0xFF1877F2),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _selectedBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _contentController,
                        style: TextStyle(fontSize: 18, color: textColor),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Bạn viết gì đi...',
                          hintStyle: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
                          border: InputBorder.none,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập nội dung bài viết';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Post Image Section
                    if (_postImage != null)
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.file(
                              _postImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _postImage = null),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildActionButton(Icons.image, 'Ảnh/Video', Colors.blue, _pickPostImage),
                        _buildActionButton(Icons.person_add, 'Gắn thẻ người khác', Colors.blue, () {}),
                        _buildActionButton(Icons.location_on, 'Thêm vị trí', Colors.red, () {}),
                        _buildActionButton(Icons.sentiment_satisfied, 'Cảm xúc/Hoạt động', Colors.yellow, () {}),
                        _buildActionButton(Icons.calendar_today, 'Tạo sự kiện', Colors.orange, () {}),
                        _buildActionButton(Icons.tag, 'Tạo cuộc thăm dò', Colors.teal, () {}),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 4.0,
                      children: [
                        for (var color in [
                          Colors.white,
                          Colors.purple,
                          Colors.red,
                          Colors.black,
                          Colors.purpleAccent,
                          Colors.orange,
                          Colors.grey,
                          Colors.black54
                        ])
                          GestureDetector(
                            onTap: () => _selectBackgroundColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Đăng',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(fontSize: 14, color: color)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}