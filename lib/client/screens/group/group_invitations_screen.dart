import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/User.dart';

class GroupInvitationsScreen extends StatefulWidget {
  const GroupInvitationsScreen({super.key});

  @override
  State<GroupInvitationsScreen> createState() => _GroupInvitationsScreenState();
}

class _GroupInvitationsScreenState extends State<GroupInvitationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadData();
  }

  Future<void> _checkUserAndLoadData() async {
    if (_auth.currentUser == null) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập để xem lời mời';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<UserModel?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> _acceptInvitation(String groupId, String invitationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'accepted'});

      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([_auth.currentUser!.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chấp nhận lời mời'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chấp nhận lời mời: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chấp nhận lời mời: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _declineInvitation(String groupId, String invitationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'declined'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối lời mời'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi từ chối lời mời: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi từ chối lời mời: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : user == null
            ? Center(
                child: Text(
                  _errorMessage ?? 'Vui lòng đăng nhập',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collectionGroup('invitations')
                    .where('invitedUserId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có lời mời nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final invitations = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
                      final groupId = invitation['groupId'];
                      final invitationId = invitation.id;
                      final groupName = invitation['groupName'] ?? 'Nhóm không tên';
                      final invitedById = invitation['invitedBy'] ?? '';

                      return FutureBuilder<UserModel?>(
                        future: _getUserData(invitedById),
                        builder: (context, userSnapshot) {
                          String inviterName = 'Người dùng ẩn danh';
                          String? inviterAvatarUrl;

                          if (userSnapshot.connectionState == ConnectionState.done &&
                              userSnapshot.hasData && userSnapshot.data != null) {
                            inviterName = userSnapshot.data!.name;
                            inviterAvatarUrl = userSnapshot.data!.avatarUrl;
                          }

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12.0),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundImage: inviterAvatarUrl != null && inviterAvatarUrl.isNotEmpty
                                    ? NetworkImage(inviterAvatarUrl)
                                    : null,
                                backgroundColor: inviterAvatarUrl == null || inviterAvatarUrl.isEmpty
                                    ? Colors.grey[400]
                                    : null,
                                child: inviterAvatarUrl == null || inviterAvatarUrl.isEmpty
                                    ? Text(
                                        inviterName.isNotEmpty ? inviterName[0].toUpperCase() : 'A',
                                        style: const TextStyle(fontSize: 18, color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Text(
                                'Lời mời tham gia nhóm: $groupName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Từ: $inviterName',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _acceptInvitation(groupId, invitationId),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Chấp nhận'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _declineInvitation(groupId, invitationId),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Từ chối'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
  }
}