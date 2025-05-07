import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/services/auth_service.dart';
import 'package:flutter_facebook_clone/models/User.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  List<UserModel> _friends = [];
  bool _isLoading = false;

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

  Future<void> _loadUserData() async {
    if (widget.uid.isEmpty) {
      print('Lỗi: UID rỗng hoặc không hợp lệ');
      if (mounted) {
        // Lấy UID từ người dùng hiện tại thay vì chuyển hướng ngay
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Tải dữ liệu cho người dùng hiện tại
          _loadUserWithUID(currentUser.uid);
        } else {
          context.go('/login');
        }
      }
      return;
    }

    _loadUserWithUID(widget.uid);
  }

  Future<void> _loadUserWithUID(String uid) async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.loadUserData(uid, _auth);

      // Tải danh sách bạn bè
      final userModel = userProvider.userModel;
      if (userModel != null) {
        final friends = await _auth.getFriends(userModel.friends);
        if (mounted) {
          setState(() {
            _friends = friends.cast<UserModel>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      // Chọn ảnh từ thư viện
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Xác nhận ảnh đại diện'),
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
                    const Text('Bạn có muốn sử dụng ảnh này làm ảnh đại diện?'),
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
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.setLoading(true); // Đặt trạng thái loading

          // Upload ảnh lên Cloudinary
          CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              imageFile.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'avatars',
              publicId:
                  '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );

          String downloadUrl = response.secureUrl;

          // Cập nhật avatarUrl trong Firestore
          await _auth.updateUserAvatar(widget.uid, downloadUrl);

          // Cập nhật UserProvider
          final currentUserModel = userProvider.userModel;
          if (currentUserModel != null) {
            userProvider.updateUser(
              currentUserModel.copyWith(avatarUrl: downloadUrl),
            );
          }

          userProvider.setLoading(false); // Tắt trạng thái loading
        }
      }
    } catch (e) {
      print('Lỗi khi chọn hoặc upload ảnh: $e');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể thay đổi ảnh avatar')),
      );
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Chỉnh sửa ảnh bìa'),
                onTap: () {
                  Navigator.pop(context);
                  // Điều hướng đến trang chỉnh sửa ảnh bìa
                  context.push('/edit-profile/cover');
                },
              ),
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('Chỉnh sửa ảnh đại diện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa thông tin cá nhân'),
                onTap: () {
                  Navigator.pop(context);
                  // Điều hướng đến trang chỉnh sửa thông tin
                  context.push('/edit-profile/info');
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_quote),
                title: const Text('Chỉnh sửa tiểu sử'),
                onTap: () {
                  Navigator.pop(context);
                  // Điều hướng đến trang chỉnh sửa tiểu sử
                  context.push('/edit-profile/bio');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userModel = userProvider.userModel;
        final bool isLoading = userProvider.isLoading || _isLoading;

        // Kiểm tra xem đây có phải là profile của người dùng hiện tại không
        final currentUser = FirebaseAuth.instance.currentUser;
        final bool isCurrentUserProfile =
            currentUser != null && currentUser.uid == widget.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(userModel?.name ?? 'Profile'),
            backgroundColor: Colors.blue[800],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/menu'),
            ),
            actions: [
              // Chỉ hiển thị nút 3 chấm nếu đây là profile của người dùng hiện tại
              if (isCurrentUserProfile)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showEditOptions,
                ),
            ],
          ),
          body:
              isLoading && userModel == null
                  ? const Center(child: CircularProgressIndicator())
                  : userModel == null
                  ? const Center(
                    child: Text('Không tìm thấy thông tin người dùng'),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Photo and Profile Picture
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Cover Photo
                            Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child:
                                  userModel.coverUrl.isNotEmpty
                                      ? Image.network(
                                        userModel.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Text(
                                                    'Cover Photo',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 24,
                                                    ),
                                                  ),
                                                ),
                                      )
                                      : Center(
                                        child: Text(
                                          'Cover Photo',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                            ),
                            // Profile Picture
                            Positioned(
                              left: 16.0,
                              top: 140.0,
                              child: GestureDetector(
                                onTap:
                                    isCurrentUserProfile
                                        ? _pickAndUploadAvatar
                                        : null,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 56,
                                        backgroundColor: Colors.grey[300],
                                        child:
                                            userModel.avatarUrl.isNotEmpty
                                                ? ClipOval(
                                                  child: Image.network(
                                                    userModel.avatarUrl,
                                                    width: 112,
                                                    height: 112,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.person,
                                                          size: 56,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                )
                                                : const Icon(
                                                  Icons.person,
                                                  size: 56,
                                                  color: Colors.grey,
                                                ),
                                      ),
                                    ),
                                    // Camera icon - chỉ hiển thị cho user hiện tại
                                    if (isCurrentUserProfile)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.blue,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Name and Bio
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 80.0,
                            right: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userModel.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (userModel.bio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    userModel.bio,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        // Profile Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin cá nhân',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Giới tính: ${userModel.gender}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        // Friends Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bạn bè',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _friends.isEmpty
                                  ? const Text('Chưa có bạn bè nào')
                                  : SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _friends.length,
                                      itemBuilder: (context, index) {
                                        final friend = _friends[index];
                                        // Tạo một key duy nhất cho mỗi item
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 16.0,
                                          ),
                                          child: Column(
                                            key: ValueKey(
                                              'friend_${friend.uid}_$index',
                                            ),
                                            children: [
                                              CircleAvatar(
                                                radius: 30,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                child:
                                                    friend.avatarUrl.isNotEmpty
                                                        ? ClipOval(
                                                          child: Image.network(
                                                            friend.avatarUrl,
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => const Icon(
                                                                  Icons.person,
                                                                  size: 30,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                          ),
                                                        )
                                                        : const Icon(
                                                          Icons.person,
                                                          size: 30,
                                                          color: Colors.grey,
                                                        ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                friend.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
