import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_facebook_clone/client/screens/group_screen.dart';

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
  String? _coverImageUrl;
  bool _isLoading = false;

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

  Future<void> _pickAndUploadCoverImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận ảnh bìa nhóm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(
                  imageFile,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
                const Text('Bạn có muốn sử dụng ảnh này làm ảnh bìa nhóm?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _isLoading = true;
          });

          CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              imageFile.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'group_covers',
              publicId: 'group_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );

          setState(() {
            _coverImageUrl = response.secureUrl;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể tải lên ảnh bìa')),
      );
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Bạn cần đăng nhập để tạo nhóm');
      }

      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'privacy': _privacy,
        'coverImageUrl': _coverImageUrl ?? '',
        'creatorUid': currentUser.uid,
        'members': [currentUser.uid],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: _coverImageUrl != null
                                ? Image.network(
                                    _coverImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        'Ảnh bìa nhóm',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      'Ảnh bìa nhóm',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: _pickAndUploadCoverImage,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
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
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả nhóm',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Quyền riêng tư',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      DropdownButtonFormField<String>(
                        value: _privacy,
                        onChanged: (value) {
                          setState(() {
                            _privacy = value!;
                          });
                        },
                        items: ['Công khai', 'Riêng tư']
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}