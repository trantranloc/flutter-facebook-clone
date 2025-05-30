import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../models/Post.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? post;

  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _captionController.text = widget.post!.content;
      if (widget.post!.imageUrls.isNotEmpty) {
        _existingImageUrl = widget.post!.imageUrls.first;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty &&
        _selectedImage == null &&
        _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung hoặc chọn ảnh.')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người dùng chưa đăng nhập')),
      );
      setState(() => _isPosting = false);
      return;
    }

    final String currentUserId = currentUser.uid;
    String name = '';
    String avatarUrl = '';

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final data = userDoc.data();
      if (data != null) {
        name = data['name'] ?? name;
        avatarUrl = data['avatarUrl'] ?? avatarUrl;
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin user: $e');
    }

    // 📤 Upload ảnh lên Cloudinary nếu có
    String? imageUrl;
    if (_selectedImage != null) {
      final cloudinary = CloudinaryPublic(
        'drtq9z4r4',
        'flutter_upload',
        cache: false,
      );
      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedImage!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrl = response.secureUrl;
      } catch (e) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải ảnh lên Cloudinary: $e')),
        );
        return;
      }
    }

    final postsCollection = FirebaseFirestore.instance.collection('posts');

    // ✏️ Chỉnh sửa bài viết
    if (widget.post != null) {
      await postsCollection.doc(widget.post!.id).update({
        'content': caption,
        'imageUrls':
            imageUrl != null
                ? [imageUrl]
                : (_existingImageUrl != null ? [_existingImageUrl!] : []),
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉnh sửa bài viết thành công!')),
      );
      Navigator.pop(context, true);
      return;
    }

    // ✅ Tạo mới bài viết
    final docRef = postsCollection.doc();
    final newPost = Post(
      id: docRef.id,
      userId: currentUserId,
      name: name,
      avatarUrl: avatarUrl,
      content: caption,
      imageUrls: imageUrl != null ? [imageUrl] : [],
      createdAt: Timestamp.now(),
      likes: 0,
      comments: 0,
      reactionCounts: {
        'like': 0,
        'love': 0,
        'care': 0,
        'haha': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      },
    );

    await docRef.set(newPost.toMap());

    setState(() => _isPosting = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đăng bài thành công!')));
    Navigator.pop(context, newPost);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post != null ? 'Chỉnh sửa bài viết' : 'Tạo bài viết mới',
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: Text(
              'Đăng',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPosting) const LinearProgressIndicator(),
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Text(
                  'Bạn đang nghĩ gì?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: null,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Viết nội dung bài viết...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null || _existingImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _selectedImage != null
                            ? Image.file(_selectedImage!)
                            : Image.network(_existingImageUrl!),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed:
                          () => setState(() {
                            _selectedImage = null;
                            _existingImageUrl = null;
                          }),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
          ],
        ),
      ),
    );
  }
}
