import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  File? _image;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Initialize Cloudinary
  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _errorMessage = null;
        });
        print('Image selected: ${pickedFile.path}');
      } else {
        setState(() {
          _errorMessage = 'Không có ảnh nào được chọn';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh: $e';
      });
      print('Error picking image: $e');
    }
  }

  // Upload image to Cloudinary and get URL
  Future<String> _uploadImageToCloudinary(String uid) async {
    if (_image == null) {
      throw Exception('Không có ảnh để tải lên');
    }

    // Check file size (limit to 5MB)
    final fileSize = await _image!.length();
    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('Ảnh quá lớn, vui lòng chọn ảnh dưới 5MB');
    }

    try {
      // Upload image to Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _image!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'user_avatars',
          publicId: '$uid${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      final downloadUrl = response.secureUrl;
      print('Image uploaded, URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Lỗi khi tải ảnh lên: $e');
    }
  }

  // Complete avatar selection and update user profile
  void _completeAvatarSelection() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn một ảnh đại diện';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Người dùng chưa đăng nhập';
      });
      return;
    }

    try {
      await user.getIdToken(true);
      print('User authenticated: ${user.uid}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi xác thực: $e';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final email = args?['email'] as String?;
      final firstName = args?['firstName'] as String?;
      final lastName = args?['lastName'] as String?;
      final gender = args?['gender'] as String?;
      final uid = user.uid;

      print('Args received: $args');

      if (email == null) {
        throw Exception('Không tìm thấy thông tin email');
      }

      final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      final userService = UserService();
      // Upload image and get URL
      final avatarUrl = await _uploadImageToCloudinary(uid);

      // Create or update UserModel
      final userModel = UserModel(
        uid: uid,
        name: fullName.isNotEmpty ? fullName : 'Unknown',
        email: email,
        avatarUrl: avatarUrl,
        coverUrl: "",
        bio: "",
        gender: gender ?? 'Unknown',
        createdAt: DateTime.now(),
      );

      // Save updated user model
      await userService.saveUser(userModel);
      print('User saved with avatarUrl: $avatarUrl');

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
      );
      context.go('/');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi cập nhật ảnh đại diện: $e';
      });
      print('Error completing avatar selection: $e');
    }
  }

  void _skipAvatarSelection() async {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || args == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể lưu thông tin.')));
      return;
    }

    final email = args['email'] as String?;
    final firstName = args['firstName'] as String?;
    final lastName = args['lastName'] as String?;
    final gender = args['gender'] as String?;
    final password = args['password'] as String?;

    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    final authService = AuthService();
    final userService = UserService();

    final userModel = UserModel(
      uid: user.uid,
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      email: email ?? '',
      avatarUrl: '',
      coverUrl: '',
      bio: '',
      gender: gender ?? 'Unknown',
      createdAt: DateTime.now(),
    );

    if (email != null && password != null) {
      await authService.signIn(email, password);
    }
    await userService.saveUser(userModel);
    print('User saved without avatar.');

    context.go('/', extra: args);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn ảnh đại diện'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm ảnh đại diện',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[800]!, width: 2),
                    image:
                        _image != null
                            ? DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _image == null
                          ? Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.blue[800],
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.blue[800],
                ),
                child: const Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeAvatarSelection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[800],
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Hoàn tất',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _skipAvatarSelection,
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
