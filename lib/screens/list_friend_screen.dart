import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:go_router/go_router.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<UserModel>> _friendsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriends();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<List<UserModel>> _fetchFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data();
    final List<String> friendUids = List<String>.from(currentUserData?['friends'] ?? []);

    if (friendUids.isEmpty) return [];

    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendUids)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> _unfriend(String friendUid) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hủy kết bạn'),
      content: const Text('Bạn có chắc muốn hủy kết bạn không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn cần đăng nhập để hủy kết bạn')),
    );
    return;
  }

  try {
    await _firestore.collection('users').doc(currentUser.uid).update({
      'friends': FieldValue.arrayRemove([friendUid]),
    });
    await _firestore.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayRemove([currentUser.uid]),
    });
    setState(() {
      _friendsFuture = _fetchFriends();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy kết bạn')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $e')),
    );
  }
}

  void _retryFetch() {
    setState(() {
      _friendsFuture = _fetchFriends();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/friend');
          },
        ),
        title: const Text(
          'Bạn bè',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _retryFetch,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final friends = snapshot.data ?? [];


          final filteredFriends = friends
              .where((friend) => friend.name.toLowerCase().contains(_searchQuery))
              .toList();

          if (filteredFriends.isEmpty && _searchQuery.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có bạn bè nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredFriends.length} người bạn',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {

                      },
                      child: const Text(
                        'Sắp xếp',
                        style: TextStyle(fontSize: 16, color: Color(0xFF1877F2)),
                      ),
                    ),
                  ],
                ),
              ),
              ...filteredFriends.map((friend) => Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        friend.avatarUrl.isNotEmpty
                            ? friend.avatarUrl
                            : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                      ),
                    ),
                    title: Text(friend.name),
                    subtitle: Text('${friend.friends.length} bạn chung'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) {
                        if (value == 'unfriend') {
                          _unfriend(friend.uid);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'unfriend',
                          child: Text('Hủy kết bạn'),
                        ),

                      ],
                    ),
                  ),
                  const Divider(),
                ],
              )),
            ],
          );
        },
      ),
    );
  }
}
