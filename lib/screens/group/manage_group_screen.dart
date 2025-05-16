import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/screens/group/group_home_screen.dart';
import '../../models/group.dart';

class ManageGroupScreen extends StatefulWidget {
  final String groupId;

  const ManageGroupScreen({super.key, required this.groupId});

  @override
  State<ManageGroupScreen> createState() => _ManageGroupScreenState();
}

class _ManageGroupScreenState extends State<ManageGroupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Group? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final doc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Đảm bảo các trường có giá trị mặc định nếu thiếu
        data['members'] ??= [];
        data['pendingRequests'] ??= [];
        data['adminUid'] ??= '';
        data['name'] ??= 'Nhóm không tên';
        data['privacy'] ??= 'Công khai';

        setState(() {
          _group = Group.fromMap(data, doc.id);
          _isLoading = false;
        });
      } else {
        throw Exception('Nhóm không tồn tại');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu nhóm: $e')));
    }
  }

  // Xóa thành viên khỏi nhóm
  Future<void> _removeMember(String memberUid) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([memberUid]),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa thành viên')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa thành viên: $e')));
    }
  }

  // Chấp nhận yêu cầu tham gia
  Future<void> _acceptRequest(String userUid) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayUnion([userUid]),
        'pendingRequests': FieldValue.arrayRemove([userUid]),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận yêu cầu')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi chấp nhận yêu cầu: $e')));
    }
  }

  // Từ chối yêu cầu tham gia
  Future<void> _rejectRequest(String userUid) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'pendingRequests': FieldValue.arrayRemove([userUid]),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi từ chối yêu cầu: $e')));
    }
  }

  // Hiển thị dialog xác nhận xóa thành viên
  Future<void> _showRemoveMemberDialog(
    String memberUid,
    String memberName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa thành viên'),
          content: Text('Bạn có chắc chắn muốn xóa $memberName khỏi nhóm?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeMember(memberUid);
              },
            ),
          ],
        );
      },
    );
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

  // Truy vấn thông tin người dùng theo batch
  Future<List<Map<String, dynamic>>> _fetchUsers(List<String> uids) async {
    if (uids.isEmpty) return [];

    final chunks = _chunkList(uids, 10);
    List<Map<String, dynamic>> users = [];

    for (var chunk in chunks) {
      final snapshot =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

      users.addAll(snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}));
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_group == null) {
      return const Scaffold(body: Center(child: Text('Nhóm không tồn tại')));
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || _group!.adminUid != currentUser.uid) {
      return const Scaffold(
        body: Center(child: Text('Chỉ admin mới có thể quản lý nhóm')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhóm'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Về trang nhóm',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => GroupHomeScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Danh sách thành viên
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Thành viên (${_group!.members.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (_group!.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Không có thành viên')),
              )
            else
              StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore
                        .collection('groups')
                        .doc(widget.groupId)
                        .snapshots(),
                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (groupSnapshot.hasError) {
                    return Center(child: Text('Lỗi: ${groupSnapshot.error}'));
                  }
                  if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
                    return const Center(child: Text('Không có dữ liệu nhóm'));
                  }

                  final groupData =
                      groupSnapshot.data!.data() as Map<String, dynamic>;
                  final members = List<String>.from(groupData['members'] ?? []);

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchUsers(members),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Không có dữ liệu thành viên'),
                        );
                      }

                      final memberData = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: memberData.length,
                        itemBuilder: (context, index) {
                          final member = memberData[index];
                          final memberUid = member['uid'];
                          final memberName = member['name'] ?? 'Không xác định';
                          final isAdmin = memberUid == _group!.adminUid;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                member['avatarUrl']?.isNotEmpty ?? false
                                    ? member['avatarUrl']
                                    : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                              ),
                            ),
                            title: Text(memberName),
                            subtitle: Text(
                              isAdmin ? 'Quản lý nhóm' : 'Thành viên',
                            ),
                            trailing:
                                !isAdmin
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _showRemoveMemberDialog(
                                            memberUid,
                                            memberName,
                                          ),
                                    )
                                    : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            // Yêu cầu tham gia (cho nhóm riêng tư)
            if (_group!.privacy == 'Riêng tư') ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Yêu cầu tham gia (${_group!.pendingRequests.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              if (_group!.pendingRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Không có yêu cầu tham gia')),
                )
              else
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      _firestore
                          .collection('groups')
                          .doc(widget.groupId)
                          .snapshots(),
                  builder: (context, groupSnapshot) {
                    if (groupSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (groupSnapshot.hasError) {
                      return Center(child: Text('Lỗi: ${groupSnapshot.error}'));
                    }
                    if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
                      return const Center(child: Text('Không có dữ liệu nhóm'));
                    }

                    final groupData =
                        groupSnapshot.data!.data() as Map<String, dynamic>;
                    final pendingRequests = List<String>.from(
                      groupData['pendingRequests'] ?? [],
                    );

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchUsers(pendingRequests),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('Không có dữ liệu yêu cầu'),
                          );
                        }

                        final requestData = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requestData.length,
                          itemBuilder: (context, index) {
                            final user = requestData[index];
                            final userUid = user['uid'];
                            final userName = user['name'] ?? 'Không xác định';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  user['avatarUrl']?.isNotEmpty ?? false
                                      ? user['avatarUrl']
                                      : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                                ),
                              ),
                              title: Text(userName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _acceptRequest(userUid),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _rejectRequest(userUid),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
