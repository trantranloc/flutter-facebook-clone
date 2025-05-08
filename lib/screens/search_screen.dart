import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/widgets/group_home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/models/user.dart';
import 'package:flutter_facebook_clone/models/group.dart';
import 'package:flutter_facebook_clone/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _userSearchResults = [];
  List<Group> _groupSearchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _userSearchResults = [];
        _groupSearchResults = [];
      });
      return;
    }
    _search(query);
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final userResults = userSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) => user.name.toLowerCase().contains(query))
          .toList();

      final groupSnapshot = await FirebaseFirestore.instance.collection('groups').get();
      final groupResults = groupSnapshot.docs
          .map((doc) => Group.fromMap(doc.data(), doc.id))
          .where((group) => group.name.toLowerCase().contains(query))
          .toList();

      setState(() {
        _userSearchResults = userResults;
        _groupSearchResults = groupResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm kiếm: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      context.go('/');
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trên Facebook',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                      ? const Center(
                          child: Text(
                            'Tìm bạn bè, bài viết hoặc trang...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : (_userSearchResults.isEmpty && _groupSearchResults.isEmpty)
                          ? const Center(
                              child: Text(
                                'Không tìm thấy người dùng hoặc nhóm nào.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView(
                              children: [
                                if (_userSearchResults.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Text(
                                      'Người dùng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  ..._userSearchResults.map((user) => ListTile(
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundImage: NetworkImage(
                                            user.avatarUrl.isNotEmpty
                                                ? user.avatarUrl
                                                : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                                          ),
                                        ),
                                        title: Text(user.name),
                                        subtitle: Text('${user.friends.length} bạn chung'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfileScreen(uid: user.uid),
                                            ),
                                          );
                                        },
                                      )),
                                ],
                                if (_groupSearchResults.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Text(
                                      'Nhóm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  ..._groupSearchResults.map((group) => ListTile(
                                        leading: Image.network(
                                          group.coverImageUrl.isNotEmpty
                                              ? group.coverImageUrl
                                              : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                                          width: 50,
                                          height: 50,
                                        ),
                                        title: Text(group.name),
                                        subtitle: Text(group.description.isNotEmpty
                                            ? group.description
                                            : '${group.privacy} • >1 thành viên'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GroupHomeScreen(groupId: group.id),
                                            ),
                                          );
                                        },
                                      )),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}