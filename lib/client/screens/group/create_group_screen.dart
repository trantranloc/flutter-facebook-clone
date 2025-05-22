import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _privacy = 'Công khai';
  File? _coverImage;
  String? _coverImageUrl;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Initialize Cloudinary
  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick cover image from gallery
  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        // Check file size (limit to 5MB)
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Ảnh bìa quá lớn, vui lòng chọn ảnh dưới 5MB';
          });
          return;
        }

        setState(() {
          _coverImage = imageFile;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Không có ảnh nào được chọn';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh bìa: $e';
      });
    }
  }

  // Upload cover image to Cloudinary
  Future<String> _uploadCoverImageToCloudinary() async {
    if (_coverImage == null) {
      return ''; // Return empty string if no cover image is selected
    }

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _coverImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'group_covers',
          publicId: 'group_cover_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      final downloadUrl = response.secureUrl;
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi khi tải ảnh bìa lên: $e');
    }
  }

  // Create group
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Bạn cần đăng nhập để tạo nhóm');
      }

      // Upload cover image if selected
      final coverUrl = await _uploadCoverImageToCloudinary();

      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'privacy': _privacy,
        'coverImageUrl': coverUrl,
        'adminUid': currentUser.uid,
        'members': [currentUser.uid],
        'pendingRequests': [],
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('groups').add(groupData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhóm thành công')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GroupScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tạo nhóm: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text(
          'Tạo nhóm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: const Text(
              'Tạo',
              style: TextStyle(color: Color(0xFF1877F2), fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image Section
                      const Text(
                        'Ảnh bìa nhóm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _pickCoverImage,
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue[800]!,
                                width: 2,
                              ),
                              image: _coverImage != null
                                  ? DecorationImage(
                                      image: FileImage(_coverImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_coverImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_coverImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                            ),
                            child: _coverImage == null && _coverImageUrl == null
                                ? Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.blue[800],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: _pickCoverImage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            backgroundColor: Colors.blue[800],
                          ),
                          child: const Text(
                            'Chọn ảnh bìa',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Group Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên nhóm',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên nhóm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Group Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả nhóm',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Privacy Settings
                      const Text(
                        'Quyền riêng tư',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _privacy,
                        onChanged: (value) {
                          setState(() {
                            _privacy = value!;
                          });
                        },
                        items: ['Công khai', 'Riêng tư']
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}