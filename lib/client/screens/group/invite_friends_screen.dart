import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/Group.dart';

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
  List<Map<String, String>> _friends = [];
  List<Map<String, String>> _filteredFriends = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  // Hàm hỗ trợ chia nhỏ danh sách thành các batch tối đa 10 phần tử
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // Truy vấn thông tin bạn bè theo batch, loại bỏ những người đã là thành viên
  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để mời bạn bè');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);

      // Loại bỏ những bạn bè đã là thành viên nhóm
      final nonMemberFriendIds =
          friendIds.where((id) => !widget.group.members.contains(id)).toList();

      final friendsData = <Map<String, String>>[];
      final chunks = _chunkList(nonMemberFriendIds, 10);

      for (var chunk in chunks) {
        final snapshot =
            await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

        friendsData.addAll(
          snapshot.docs.map((doc) {
            final data = doc.data();
            final name =
                data['name']?.toString().trim() ?? 'Người dùng ẩn danh';
            return {
              'friendId': doc.id,
              'name': name,
              'avatarUrl': data['avatarUrl']?.toString() ?? '',
            };
          }),
        );
      }

      setState(() {
        _friends = friendsData;
        _filteredFriends = friendsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách bạn bè: $e';
        _isLoading = false;
      });
    }
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredFriends =
          _friends.where((friend) {
            final name = friend['name']?.toLowerCase() ?? '';
            return name.contains(query);
          }).toList();
    });
  }

  Future<void> _inviteFriend(String friendId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để mời bạn bè');
      }

      // Kiểm tra xem đã có lời mời chưa
      final invitationDoc =
          await _firestore
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

      // Xóa bạn khỏi danh sách sau khi mời
      setState(() {
        _friends.removeWhere((friend) => friend['friendId'] == friendId);
        _filteredFriends.removeWhere(
          (friend) => friend['friendId'] == friendId,
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi gửi lời mời: $e';
      });
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
        appBar: AppBar(
          title: const Text(
            'Mời bạn bè',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Chỉ quản trị viên có thể mời bạn bè')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mời bạn bè',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bạn bè',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterFriends();
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child:
                        _filteredFriends.isEmpty
                            ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? 'Không có bạn bè nào để mời'
                                    : 'Không tìm thấy bạn bè phù hợp',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              itemCount: _filteredFriends.length,
                              itemBuilder: (context, index) {
                                final friend = _filteredFriends[index];
                                final friendId = friend['friendId']!;
                                final friendName = friend['name']!;
                                final friendAvatarUrl = friend['avatarUrl'];

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          friendAvatarUrl != null &&
                                                  friendAvatarUrl.isNotEmpty
                                              ? NetworkImage(friendAvatarUrl)
                                              : null,
                                      child:
                                          friendAvatarUrl == null ||
                                                  friendAvatarUrl.isEmpty
                                              ? Text(
                                                friendName.isNotEmpty
                                                    ? friendName[0]
                                                        .toUpperCase()
                                                    : 'A',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      friendName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : () => _inviteFriend(friendId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1877F2,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Mời',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
