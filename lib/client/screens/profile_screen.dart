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
import 'package:flutter_facebook_clone/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Post.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final bool hideAppBar;

  const ProfileScreen({super.key, required this.uid, this.hideAppBar = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  List<UserModel> _friends = [];
  List<Post> _posts = [];
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
    fetchUserPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchUserPosts() async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).userModel;

      if (currentUser == null) return;

      // Check if user is allowed to view posts
      final isAllowed =
          currentUser.uid == widget.uid ||
          currentUser.friends.contains(widget.uid);

      if (!isAllowed) {
        setState(() {
          _posts = [];
        });
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: widget.uid)
              .orderBy('createdAt', descending: true)
              .get();

      final postsWithShare = await Future.wait(
        snapshot.docs.map((doc) => Post.fromDocumentWithShare(doc)),
      );

      setState(() {
        _posts = postsWithShare;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  String timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'Vừa xong';
    if (duration.inHours < 1) return '${duration.inMinutes} phút trước';
    if (duration.inDays < 1) return '${duration.inHours} giờ trước';
    return '${duration.inDays} ngày trước';
  }

  Widget _buildPostsSection() {
    final isCurrentUserProfile =
        FirebaseAuth.instance.currentUser?.uid == widget.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bài viết', style: Theme.of(context).textTheme.titleMedium),
              if (isCurrentUserProfile)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    );
                    fetchUserPosts();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          _posts.isEmpty
              ? Center(
                child:
                    FirebaseAuth.instance.currentUser?.uid != widget.uid &&
                            !Provider.of<UserProvider>(
                              context,
                              listen: false,
                            ).userModel!.friends.contains(widget.uid)
                        ? const Text('Bạn không có quyền xem bài viết này')
                        : const Text('Chưa có bài viết nào'),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return PostCard(
                    userId: post.userId,
                    postId: post.id,
                    name: post.name,
                    avatarUrl: post.avatarUrl,
                    time: timeAgo(post.createdAt.toDate()),
                    caption: post.content,
                    imageUrl:
                        post.imageUrls.isNotEmpty ? post.imageUrls[0] : '',
                    likes: post.likes,
                    comments: 0,
                    shares: 0,
                    reactionCounts: post.reactionCounts,
                    reactionType: post.reactionType,
                    sharedFromPostId: post.sharedPostId,
                    sharedFromUserName: post.sharedFromUserName,
                    sharedFromAvatarUrl: post.sharedFromAvatarUrl,
                    sharedFromContent: post.sharedFromContent,
                    sharedFromImageUrls: post.sharedFromImageUrls,
                  );
                },
              ),
        ],
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData(widget.uid, _userService);

      // Load friends list
      final userModel = userProvider.userModel;
      if (userModel != null) {
        final friends = await _userService.getFriends(userModel.friends);
        if (mounted) {
          setState(() {
            _friends = friends;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    } finally {
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
      print('Error selecting or uploading image: $e');
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
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
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
      backgroundColor: Theme.of(context).primaryColor,
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
        final bool shouldHideAppBar =
            widget.hideAppBar && !isCurrentUserProfile;

        if (userModel != null) {
          _animationController.forward();
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar:
                  shouldHideAppBar
                      ? null
                      : AppBar(
                        elevation: 0,
                        backgroundColor: Theme.of(context).cardColor,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () => context.go('/menu'),
                        ),
                        title: Text(
                          userModel?.name ?? 'Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        actions: [
                          if (isCurrentUserProfile)
                            IconButton(
                              icon: Icon(
                                Icons.qr_code,
                                color: Theme.of(context).iconTheme.color,
                              ),
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
                      ? Center(
                        child: Text(
                          'Không tìm thấy thông tin người dùng',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
                                      color: Theme.of(context).dividerColor,
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
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.image,
                                                          size: 40,
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).disabledColor,
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          'Ảnh bìa',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
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
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).disabledColor,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Ảnh bìa',
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodyMedium,
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
                                                  color: Theme.of(context)
                                                      .shadowColor
                                                      .withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 60,
                                              backgroundColor:
                                                  Theme.of(context).cardColor,
                                              child: CircleAvatar(
                                                radius: 56,
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).dividerColor,
                                                child:
                                                    userModel
                                                            .avatarUrl
                                                            .isNotEmpty
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
                                                                ) => Icon(
                                                                  Icons.person,
                                                                  size: 56,
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).disabledColor,
                                                                ),
                                                          ),
                                                        )
                                                        : Icon(
                                                          Icons.person,
                                                          size: 56,
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).disabledColor,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          if (isCurrentUserProfile)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
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
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
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
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleLarge,
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
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
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
                                        Text(
                                          'Thông tin cá nhân',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
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
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
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
                                        Text(
                                          'Bạn bè',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${_friends.length})',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
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
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).disabledColor,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Chưa có bạn bè nào',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
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
                                                            Theme.of(
                                                              context,
                                                            ).dividerColor,
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
                                                                        ) => Icon(
                                                                          Icons
                                                                              .person,
                                                                          size:
                                                                              30,
                                                                          color:
                                                                              Theme.of(
                                                                                context,
                                                                              ).disabledColor,
                                                                        ),
                                                                  ),
                                                                )
                                                                : Icon(
                                                                  Icons.person,
                                                                  size: 30,
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).disabledColor,
                                                                ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    SizedBox(
                                                      width: 60,
                                                      child: Text(
                                                        friend.name,
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
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
                              _buildPostsSection(),
                            ],
                          ),
                        ),
                      ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
        const SizedBox(width: 8),
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
