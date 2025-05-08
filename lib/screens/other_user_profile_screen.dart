import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import 'package:flutter_facebook_clone/models/User.dart';
import 'package:go_router/go_router.dart';

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
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
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
        final otherUserDoc = await _firestore.collection('users').doc(widget.uid).get();
        if (otherUserDoc.exists) {
          setState(() {
            _hasPendingRequest = _currentUser!.pendingRequests.contains(widget.uid);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận bạn bè')),
      );
      
      // Refresh the friends list
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy kết bạn')),
      );
      
      // Refresh the friends list
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
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
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
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
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
      ),
      icon: const Icon(Icons.person_add),
      label: const Text('Thêm bạn bè'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userModel == null
              ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
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
                          decoration: BoxDecoration(color: Colors.grey[300]),
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
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.grey[200],
                              child:
                                  _userModel!.avatarUrl.isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          _userModel!.avatarUrl,
                                          width: 112,
                                          height: 112,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
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
                        ),
                      ],
                    ),
                    // Name and Bio
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 80),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userModel!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_userModel!.bio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _userModel!.bio,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          // Add Friend Button
                          _buildFriendButton(),
                          
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
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
                      decoration: const BoxDecoration(color: Colors.white),
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
                                              backgroundColor: Colors.grey[200],
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
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      )
                                                      : const Icon(
                                                        Icons.person,
                                                        size: 30,
                                                        color: Colors.grey,
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
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
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