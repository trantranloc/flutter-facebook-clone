import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final String editType; // 'cover', 'info', 'bio'

  const EditProfileScreen({super.key, required this.editType});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedGender = '';
  bool _isLoading = false;

  // Cloudinary setup
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
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userModel = userProvider.userModel;

    if (userModel != null) {
      _nameController.text = userModel.name;
      _bioController.text = userModel.bio;
      _selectedGender = userModel.gender;
    } else {
      try {
        await userProvider.loadUserData(currentUser.uid, _userService);
        final loadedUser = userProvider.userModel;
        if (loadedUser != null && mounted) {
          setState(() {
            _nameController.text = loadedUser.name;
            _bioController.text = loadedUser.bio;
            _selectedGender = loadedUser.gender;
          });
        }
      } catch (e) {
        print('Lỗi khi tải thông tin người dùng: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải thông tin người dùng')),
          );
        }
      }
    }
  }

  // Helper method to display image depending on platform
  Widget displayImageFromFile(
    File imageFile, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (kIsWeb) {
      // For web, we need to convert the File to a Uint8List and use Image.memory
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
            );
          } else {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else {
      // For mobile platforms, use Image.file directly
      return Image.file(imageFile, width: width, height: height, fit: fit);
    }
  }

  Future<void> _pickAndUploadCoverPhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Chọn ảnh từ thư viện
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Xác nhận ảnh bìa'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: displayImageFromFile(imageFile, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bạn có muốn sử dụng ảnh này làm ảnh bìa?'),
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
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không tìm thấy thông tin người dùng'),
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Upload ảnh lên Cloudinary
          CloudinaryResponse response;

          if (kIsWeb) {
            // For web, upload using bytes
            final bytes = await imageFile.readAsBytes();
            response = await cloudinary.uploadFile(
              CloudinaryFile.fromBytesData(
                bytes,
                identifier:
                    '${currentUser.uid}_cover_${DateTime.now().millisecondsSinceEpoch}',
                folder: 'covers',
              ),
            );
          } else {
            // For mobile, upload from file
            response = await cloudinary.uploadFile(
              CloudinaryFile.fromFile(
                imageFile.path,
                resourceType: CloudinaryResourceType.Image,
                folder: 'covers',
                publicId:
                    '${currentUser.uid}_cover_${DateTime.now().millisecondsSinceEpoch}',
              ),
            );
          }

          String downloadUrl = response.secureUrl;

          // Cập nhật coverUrl trong Firestore
          await _userService.updateUserCover(currentUser.uid, downloadUrl);

          // Cập nhật UserProvider
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final currentUserModel = userProvider.userModel;
          if (currentUserModel != null) {
            userProvider.updateUser(
              currentUserModel.copyWith(coverUrl: downloadUrl),
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật ảnh bìa thành công')),
            );
            context.go('/profile');
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi chọn hoặc upload ảnh bìa: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không thể thay đổi ảnh bìa')),
        );
      }
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Cập nhật thông tin cá nhân trong Firestore
      await _userService.updateUserInfo(
        currentUser.uid,
        _nameController.text,
        _selectedGender,
      );

      // Cập nhật UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserModel = userProvider.userModel;
      if (currentUserModel != null) {
        userProvider.updateUser(
          currentUserModel.copyWith(
            name: _nameController.text,
            gender: _selectedGender,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        context.go('/profile');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi cập nhật thông tin: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không thể cập nhật thông tin')),
        );
      }
    }
  }

  Future<void> _updateUserBio() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Cập nhật bio trong Firestore
      await _userService.updateUserBio(currentUser.uid, _bioController.text);

      // Cập nhật UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserModel = userProvider.userModel;
      if (currentUserModel != null) {
        userProvider.updateUser(
          currentUserModel.copyWith(bio: _bioController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật tiểu sử thành công')),
        );
        context.go('/profile');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi cập nhật tiểu sử: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không thể cập nhật tiểu sử')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getScreenTitle(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1877F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1877F2), Colors.white],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildEditForm(),
                    ),
                  ),
                ),
              ),
    );
  }

  String _getScreenTitle() {
    switch (widget.editType) {
      case 'cover':
        return 'Chỉnh sửa ảnh bìa';
      case 'info':
        return 'Chỉnh sửa thông tin cá nhân';
      case 'bio':
        return 'Chỉnh sửa tiểu sử';
      default:
        return 'Chỉnh sửa hồ sơ';
    }
  }

  Widget _buildEditForm() {
    switch (widget.editType) {
      case 'cover':
        return _buildCoverEditForm();
      case 'info':
        return _buildInfoEditForm();
      case 'bio':
        return _buildBioEditForm();
      default:
        return const Center(child: Text('Không tìm thấy mục chỉnh sửa'));
    }
  }

  Widget _buildCoverEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final userModel = userProvider.userModel;
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child:
                    userModel?.coverUrl.isNotEmpty == true
                        ? Image.network(
                          userModel!.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Cover Photo',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cover Photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickAndUploadCoverPhoto,
          icon: const Icon(Icons.photo_library),
          label: const Text('Chọn ảnh bìa mới'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên hiển thị',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1877F2),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Nhập tên của bạn',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1877F2)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1877F2),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender.isNotEmpty ? _selectedGender : null,
          decoration: InputDecoration(
            hintText: 'Chọn giới tính',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1877F2)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: 'Nam', child: Text('Nam')),
            DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
            DropdownMenuItem(value: 'Khác', child: Text('Khác')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateUserInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiểu sử',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1877F2),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          decoration: InputDecoration(
            hintText: 'Viết về bản thân bạn...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1877F2)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 5,
          maxLength: 200,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateUserBio,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
