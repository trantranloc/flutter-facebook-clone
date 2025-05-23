import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/client/screens/group/create_post_screen_group.dart';
import 'package:flutter_facebook_clone/client/screens/group/events_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/invite_friends_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/manage_group_screen.dart';
import 'package:flutter_facebook_clone/models/Group.dart' show GroupPrivacy;
import 'package:flutter_facebook_clone/models/group.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:intl/intl.dart';


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
  String? _userAvatarUrl;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, bool> _showComments = {};

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    _loadUserData();
  }

  @override
  void dispose() {
    _commentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Load group data from Firestore
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
        _errorMessage = 'Lỗi khi tải dữ liệu nhóm: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu nhóm: $e')),
      );
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userAvatarUrl = userDoc.data()?['avatarUrl']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin người dùng: $e';
      });
    }
  }

  // Pick and upload new cover image
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
        _isLoading = false;
        _errorMessage = 'Lỗi khi cập nhật ảnh bìa: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật ảnh bìa: $e')),
      );
    }
  }

  // Delete group
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

  // Show delete confirmation dialog
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

  // Helper function to calculate relative time
  String _getRelativeTime(dynamic timestamp) {
    if (timestamp == null) return 'Vừa xong';
    DateTime postTime;
    if (timestamp is Timestamp) {
      postTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      postTime = timestamp;
    } else {
      return 'Vừa xong';
    }
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày';
    } else {
      return DateFormat('dd/MM/yyyy').format(postTime);
    }
  }

  // Fetch user data with caching
  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()! as Map<String, dynamic>;
      _userCache[userId] = userData;
      return userData;
    }
    return {'name': 'Người dùng ẩn danh', 'avatarUrl': ''};
  }

  // Toggle like for a post
  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final isLiked = currentLikes.contains(userId);

    if (isLiked) {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // Add a new comment to a post
  Future<void> _addComment(String postId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final comment = {
      'userId': user.uid,
      'content': content,
      'createdAt': DateTime.now(), // Use client-side timestamp
    };

    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(postId)
        .update({
      'comments': FieldValue.arrayUnion([comment]),
    });

    // Clear the comment input field
    _commentControllers[postId]?.clear();
  }

  // Toggle comments visibility
  void _toggleCommentsVisibility(String postId) {
    setState(() {
      _showComments[postId] = !(_showComments[postId] ?? false);
    });
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
                // TODO: Thêm logic chỉnh sửa
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
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
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
                          _group!.privacy == GroupPrivacy.public
                              ? 'Nhóm Công khai • ${_group!.members.length} thành viên'
                              : 'Nhóm Riêng tư • ${_group!.members.length} thành viên',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
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
                      alignment: WrapAlignment.start,
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
                          label: const Text(
                            'Mời bạn bè',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageGroupScreen(
                                  groupId: widget.groupId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text(
                            'Quản lý',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventsScreen(groupId: widget.groupId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.event, size: 18),
                          label: const Text(
                            'Sự kiện',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 5, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                              ? NetworkImage(_userAvatarUrl!)
                              : null,
                          child: _userAvatarUrl == null || _userAvatarUrl!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatePostScreenGroup(
                                    groupId: widget.groupId,
                                    groupName: _group?.name ?? 'Nhóm',
                                  ),
                                ),
                              );
                            },
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
                              enabled: false,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.photo,
                            color: Color(0xFF1877F2),
                          ),
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
                        _buildOption(Icons.edit, 'Bài viết ẩn danh', Colors.green),
                        _buildOption(Icons.camera_alt, 'Cảm xúc', Colors.yellow),
                        _buildOption(Icons.poll, 'Thăm dò', Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 2, color: Colors.grey),
                  // Display posts
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('posts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Lỗi khi tải bài đăng'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Chưa có bài đăng nào.'),
                        );
                      }

                      final posts = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final data = post.data() as Map<String, dynamic>;
                          final content = data['content']?.toString() ?? '';
                          final imageUrl = data['imageUrl']?.toString();
                          final backgroundColor = Color(data['backgroundColor'] ?? 0xFFFFFFFF);
                          final createdBy = data['createdBy']?.toString() ?? '';
                          final createdAt = data['createdAt'] as Timestamp?;
                          final likes = data['likes'] as List<dynamic>? ?? [];
                          final comments = data['comments'] as List<dynamic>? ?? [];
                          final postId = post.id;

                          // Initialize comment controller for this post
                          _commentControllers[postId] ??= TextEditingController();

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _fetchUserData(createdBy),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              if (userSnapshot.hasError || !userSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final userData = userSnapshot.data!;
                              final userName = userData['name'] as String;
                              final userAvatar = userData['avatarUrl'] as String;
                              final currentUser = _auth.currentUser;
                              final isLiked = currentUser != null && likes.contains(currentUser.uid);

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // User info and timestamp
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: userAvatar.isNotEmpty
                                                ? NetworkImage(userAvatar)
                                                : null,
                                            child: userAvatar.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 20,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  _getRelativeTime(createdAt),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Post content with background color
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          content,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: backgroundColor == Colors.white
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      // Post image
                                      if (imageUrl != null && imageUrl.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 200,
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Text(
                                                      'Không thể tải ảnh',
                                                      style: TextStyle(color: Colors.grey),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      // Interaction bar
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  size: 20,
                                                  color: isLiked ? Colors.red : Colors.grey,
                                                ),
                                                onPressed: () {
                                                  if (currentUser != null) {
                                                    _toggleLike(postId, likes);
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${likes.length}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.comment,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () => _toggleCommentsVisibility(postId),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${comments.length}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Comment section
                                      if (_showComments[postId] ?? false) ...[
                                        const Divider(),
                                        // Existing comments
                                        ...comments.asMap().entries.map((entry) {
                                          final comment = entry.value as Map<String, dynamic>;
                                          final commentUserId = comment['userId'] as String;
                                          final commentContent = comment['content'] as String;
                                          final commentCreatedAt = comment['createdAt'];

                                          DateTime? displayTime;
                                          if (commentCreatedAt is Timestamp) {
                                            displayTime = commentCreatedAt.toDate();
                                          } else if (commentCreatedAt is DateTime) {
                                            displayTime = commentCreatedAt;
                                          }

                                          return FutureBuilder<Map<String, dynamic>>(
                                            future: _fetchUserData(commentUserId),
                                            builder: (context, commentUserSnapshot) {
                                              if (commentUserSnapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox.shrink();
                                              }
                                              if (commentUserSnapshot.hasError ||
                                                  !commentUserSnapshot.hasData) {
                                                return const SizedBox.shrink();
                                              }

                                              final commentUserData = commentUserSnapshot.data!;
                                              final commentUserName = commentUserData['name'] as String;
                                              final commentUserAvatar =
                                                  commentUserData['avatarUrl'] as String;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundImage: commentUserAvatar.isNotEmpty
                                                          ? NetworkImage(commentUserAvatar)
                                                          : null,
                                                      child: commentUserAvatar.isEmpty
                                                          ? const Icon(
                                                              Icons.person,
                                                              size: 16,
                                                              color: Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                commentUserName,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                _getRelativeTime(displayTime != null
                                                                    ? Timestamp.fromDate(displayTime)
                                                                    : null),
                                                                style: const TextStyle(
                                                                  color: Colors.grey,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            commentContent,
                                                            style: const TextStyle(fontSize: 14),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        }),
                                        const SizedBox(height: 8),
                                        // Add comment input
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _commentControllers[postId],
                                                decoration: InputDecoration(
                                                  hintText: 'Viết bình luận...',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[200],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.send,
                                                color: Color(0xFF1877F2),
                                              ),
                                              onPressed: () {
                                                final commentText = _commentControllers[postId]!.text.trim();
                                                if (commentText.isNotEmpty) {
                                                  _addComment(postId, commentText);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
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
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}