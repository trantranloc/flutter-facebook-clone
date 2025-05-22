import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/group.dart';

class InviteFriendsScreen extends StatefulWidget {
  final String groupId;
  final Group group;

  const InviteFriendsScreen({
    super.key,
    required this.groupId,
    required this.group,
  });

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, String>> _friends = []; // Lưu {friendId, name, avatarUrl}
  List<Map<String, String>> _filteredFriends = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);

      final friendsData = <Map<String, String>>[];
      for (var friendId in friendIds) {
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists && friendDoc.data() != null) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          final name = friendData['name']?.toString().trim() ?? 'Người dùng ẩn danh';
          friendsData.add({
            'friendId': friendId,
            'name': name,
            'avatarUrl': friendData['avatarUrl']?.toString() ?? '',
          });
        }
      }

      setState(() {
        _friends = friendsData;
        _filteredFriends = friendsData;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách bạn bè: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredFriends = _friends.where((friend) {
        final name = friend['name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _inviteFriend(String friendId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để mời bạn bè')),
        );
        return;
      }

      // Kiểm tra xem bạn đã là thành viên hoặc có lời mời chưa
      if (widget.group.members.contains(friendId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng đã là thành viên nhóm')),
        );
        return;
      }
      final invitationDoc = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('invitations')
          .doc(friendId)
          .get();
      if (invitationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng đã được mời trước đó')),
        );
        return;
      }

      // Gửi lời mời
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('invitations')
          .doc(friendId)
          .set({
        'invitedBy': user.uid,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'invitedUserId': friendId,
        'groupId': widget.groupId,
        'groupName': widget.group.name,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi lời mời: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null || widget.group.adminUid != user.uid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mời bạn bè')),
        body: const Center(child: Text('Chỉ quản trị viên có thể mời bạn bè')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mời bạn bè'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bạn bè',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.clear),
              ),
              onChanged: (value) => _filterFriends(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? const Center(child: Text('Không có bạn bè để mời'))
                    : ListView.builder(
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final friendId = friend['friendId']!;
                          final friendName = friend['name']!;
                          final friendAvatarUrl = friend['avatarUrl'];

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: friendAvatarUrl != null && friendAvatarUrl.isNotEmpty
                                  ? NetworkImage(friendAvatarUrl)
                                  : null,
                              child: friendAvatarUrl == null || friendAvatarUrl.isEmpty
                                  ? Text(
                                      friendName.isNotEmpty ? friendName[0].toUpperCase() : 'A',
                                      style: const TextStyle(fontSize: 16),
                                    )
                                  : null,
                            ),
                            title: Text(friendName),
                            trailing: ElevatedButton(
                              onPressed: _isLoading ? null : () => _inviteFriend(friendId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Mời'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}