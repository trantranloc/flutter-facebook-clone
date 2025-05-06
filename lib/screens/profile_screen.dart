import 'package:flutter/material.dart';
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
  UserModel? _userModel;
  bool _isLoading = true;
  List<UserModel> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userModel = await _auth.getUser(widget.uid);
      final friends =
          userModel != null ? await _auth.getFriends(userModel.friends) : [];

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _friends = friends.cast<UserModel>();
          _isLoading = false;
        });
      }

      if (userModel == null) {
        print('Không tìm thấy thông tin người dùng');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue[800],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                              _userModel?.avatarUrl?.isNotEmpty ?? false
                                  ? Image.network(
                                    _userModel!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
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
                          top: 140.0, // Half of avatar overlaps the cover
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.grey[300],
                              child:
                                  _userModel?.avatarUrl.isNotEmpty ?? false
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
                    // Name
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        top: 80.0,
                        right: 16.0,
                      ),
                      child: Text(
                        _userModel?.name ?? 'Your Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                              Text(
                                'Giới tính: ${_userModel?.gender ?? 'Unknown'}',
                              ),
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
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16.0,
                                      ),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.grey[300],
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
  }
}
