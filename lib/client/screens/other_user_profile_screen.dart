import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_facebook_clone/providers/theme_provider.dart'; // Import ThemeProvider

class OtherUserProfileScreen extends StatefulWidget {
  final String uid;

  const OtherUserProfileScreen({super.key, required this.uid});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _friends = [];
  bool _isLoading = false;
  UserModel? _userModel;
  UserModel? _currentUser;

  // Friend relationship status
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  bool _hasSentRequest = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData(widget.uid, _userService);

      final userModel = userProvider.userModel;
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
        });

        // Load friends list
        final friends = await _userService.getFriends(userModel.friends);
        if (mounted) {
          setState(() {
            _friends = friends;
          });
        }

        // Load current user and check relationship
        await _loadCurrentUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải thông tin: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Get current user data
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUser = UserModel.fromMap(userData);

          // Check if they are friends
          _isFriend = _currentUser!.friends.contains(widget.uid);

          // Check if current user sent a request to this user
          _hasSentRequest = _userModel!.pendingRequests.contains(currentUserId);
        });

        // Check if this user sent a request to current user
        final otherUserDoc =
            await _firestore.collection('users').doc(widget.uid).get();
        if (otherUserDoc.exists) {
          setState(() {
            _hasPendingRequest = _currentUser!.pendingRequests.contains(
              widget.uid,
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error loading current user: $e');
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Add current user ID to other user's pendingRequests
      await _firestore.collection('users').doc(widget.uid).update({
        'pendingRequests': FieldValue.arrayUnion([currentUserId]),
      });

      setState(() {
        _hasSentRequest = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _cancelFriendRequest() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Remove current user ID from other user's pendingRequests
      await _firestore.collection('users').doc(widget.uid).update({
        'pendingRequests': FieldValue.arrayRemove([currentUserId]),
      });

      setState(() {
        _hasSentRequest = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _acceptFriendRequest() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Add to both users' friends lists and remove from pending requests
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([widget.uid]),
        'pendingRequests': FieldValue.arrayRemove([widget.uid]),
      });

      await _firestore.collection('users').doc(widget.uid).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      setState(() {
        _isFriend = true;
        _hasPendingRequest = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xác nhận bạn bè')));

      // Refresh the friends list
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _removeFriend() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Remove from both users' friends lists
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([widget.uid]),
      });

      await _firestore.collection('users').doc(widget.uid).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      setState(() {
        _isFriend = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy kết bạn')));

      // Refresh the friends list
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Widget _buildFriendButton() {
    // Cannot send friend request to yourself
    if (_auth.currentUser?.uid == widget.uid) {
      return const SizedBox.shrink();
    }

    // Already friends
    if (_isFriend) {
      return ElevatedButton.icon(
        onPressed: _removeFriend,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).dividerColor,
          foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          minimumSize: const Size(double.infinity, 40),
        ),
        icon: const Icon(Icons.check),
        label: const Text('Bạn bè'),
      );
    }

    // Pending request from other user
    if (_hasPendingRequest) {
      return ElevatedButton.icon(
        onPressed: _acceptFriendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Xác nhận lời mời kết bạn'),
      );
    }

    // User already sent request
    if (_hasSentRequest) {
      return ElevatedButton.icon(
        onPressed: _cancelFriendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).dividerColor,
          foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          minimumSize: const Size(double.infinity, 40),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Hủy lời mời'),
      );
    }

    // Can send friend request
    return ElevatedButton.icon(
      onPressed: _sendFriendRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
      ),
      icon: const Icon(Icons.person_add),
      label: const Text('Thêm bạn bè'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(
              _userModel?.name ?? 'Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userModel == null
                  ? Center(
                    child: Text(
                      'Không tìm thấy thông tin người dùng',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor,
                              ),
                              child:
                                  _userModel!.coverUrl.isNotEmpty
                                      ? Image.network(
                                        _userModel!.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildPlaceholder('Ảnh bìa'),
                                      )
                                      : _buildPlaceholder('Ảnh bìa'),
                            ),
                            // Profile Picture
                            Positioned(
                              left: 16.0,
                              top: 140.0,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).cardColor,
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor:
                                      Theme.of(context).dividerColor,
                                  child:
                                      _userModel!.avatarUrl.isNotEmpty
                                          ? ClipOval(
                                            child: Image.network(
                                              _userModel!.avatarUrl,
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
                                                Theme.of(context).disabledColor,
                                          ),
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
                              Text(
                                _userModel!.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (_userModel!.bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _userModel!.bio,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Add Friend Button
                              _buildFriendButton(),
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
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                Icons.person_outline,
                                'Giới tính',
                                _userModel!.gender,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.email_outlined,
                                'Email',
                                _userModel!.email,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Tham gia',
                                '${_userModel!.createdAt.day}/${_userModel!.createdAt.month}/${_userModel!.createdAt.year}',
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
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_friends.length})',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                                              Theme.of(context).disabledColor,
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
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              OtherUserProfileScreen(
                                                                uid: friend.uid,
                                                              ),
                                                    ),
                                                  );
                                                },
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
                                                              friend.avatarUrl,
                                                              width: 60,
                                                              height: 60,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) => Icon(
                                                                    Icons
                                                                        .person,
                                                                    size: 30,
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
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
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
        );
      },
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: Theme.of(context).disabledColor),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
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
