import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/models/User.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  List<UserModel> _friends = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      await userProvider.loadUserData(uid, _userService);

      // Tải danh sách bạn bè
      final userModel = userProvider.userModel;
      if (userModel != null) {
        final friends = await _userService.getFriends(userModel.friends);
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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Xác nhận ảnh đại diện',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        imageFile,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn có muốn sử dụng ảnh này làm ảnh đại diện?',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
          userProvider.setLoading(true);

          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );

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
          await _userService.updateUserAvatar(widget.uid, downloadUrl);

          final currentUserModel = userProvider.userModel;
          if (currentUserModel != null) {
            userProvider.updateUser(
              currentUserModel.copyWith(avatarUrl: downloadUrl),
            );
          }

          // Hide loading dialog
          Navigator.of(context).pop();
          userProvider.setLoading(false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi chọn hoặc upload ảnh: $e');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thay đổi ảnh đại diện'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.blue),
                ),
                title: const Text('Chỉnh sửa ảnh bìa'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/edit-profile/cover');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.face, color: Colors.purple),
                ),
                title: const Text('Chỉnh sửa ảnh đại diện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.green),
                ),
                title: const Text('Chỉnh sửa thông tin cá nhân'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/edit-profile/info');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.format_quote, color: Colors.orange),
                ),
                title: const Text('Chỉnh sửa tiểu sử'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/edit-profile/bio');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings, color: Colors.red),
                ),
                title: const Text('Cài đặt tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.blue),
                ),
                title: const Text('Thay đổi ảnh đại diện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Tạo tin'),
                onTap: () {
                  Navigator.pop(context);
                  _createStory();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _createStory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tạo tin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chức năng tạo tin đang được phát triển.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userModel = userProvider.userModel;
        final bool isLoading = userProvider.isLoading || _isLoading;
        final currentUser = FirebaseAuth.instance.currentUser;
        final bool isCurrentUserProfile =
            currentUser != null && currentUser.uid == widget.uid;

        if (userModel != null) {
          _animationController.forward();
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.go('/menu'),
            ),
            title: Text(
              userModel?.name ?? 'Profile',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              if (isCurrentUserProfile)
                IconButton(
                  icon: const Icon(Icons.qr_code, color: Colors.black),
                  onPressed: () {
                    // Show QR code
                  },
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
                  : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
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
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                ),
                                child:
                                    userModel.coverUrl.isNotEmpty
                                        ? Image.network(
                                          userModel.coverUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: Colors.grey[400],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Ảnh bìa',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        )
                                        : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Ảnh bìa',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
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
                                          ? _showAvatarOptions
                                          : null,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.white,
                                          child: CircleAvatar(
                                            radius: 56,
                                            backgroundColor: Colors.grey[200],
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
                                                              color:
                                                                  Colors.grey,
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
                                      ),
                                      if (isCurrentUserProfile)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF1877F2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
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
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 80),
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userModel.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUserProfile)
                                      IconButton(
                                        icon: const Icon(Icons.more_horiz),
                                        onPressed: _showEditOptions,
                                      ),
                                  ],
                                ),
                                if (userModel.bio.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    userModel.bio,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Thông tin cá nhân',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'Giới tính',
                                  userModel.gender,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.email_outlined,
                                  'Email',
                                  userModel.email,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Tham gia',
                                  '${userModel.createdAt.day}/${userModel.createdAt.month}/${userModel.createdAt.year}',
                                ),
                              ],
                            ),
                          ),
                          // Friends Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Bạn bè',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${_friends.length})',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _friends.isEmpty
                                    ? Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Chưa có bạn bè nào',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _friends.length,
                                        itemBuilder: (context, index) {
                                          final friend = _friends[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16.0,
                                            ),
                                            child: Column(
                                              key: ValueKey(
                                                'friend_${friend.uid}_$index',
                                              ),
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    child:
                                                        friend
                                                                .avatarUrl
                                                                .isNotEmpty
                                                            ? ClipOval(
                                                              child: Image.network(
                                                                friend
                                                                    .avatarUrl,
                                                                width: 60,
                                                                height: 60,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) => const Icon(
                                                                      Icons
                                                                          .person,
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
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                    friend.name,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
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
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
