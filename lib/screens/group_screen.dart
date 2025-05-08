import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/screens/home_screen.dart';
import 'package:flutter_facebook_clone/screens/search_screen.dart';
import 'package:flutter_facebook_clone/widgets/create_group_screen.dart';
import 'package:flutter_facebook_clone/widgets/group_home_screen.dart';
import 'package:flutter_facebook_clone/models/group.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Group>> _fetchGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    return snapshot.docs
        .map((doc) => Group.fromMap(doc.data(), doc.id))
        .toList();
  }

  void _retryFetch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text(
          'Nhóm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Group>>(
        future: _fetchGroups(),
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
          final groups = snapshot.data ?? [];

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Icon(Icons.group, color: Color(0xFF1877F2)),
                              SizedBox(width: 4),
                              Text(
                                'Nhóm của bạn',
                                style: TextStyle(color: Color(0xFF1877F2)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Icon(Icons.explore, color: Color(0xFF1877F2)),
                              SizedBox(width: 4),
                              Text(
                                'Khám phá',
                                style: TextStyle(color: Color(0xFF1877F2)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Icon(Icons.mail, color: Color(0xFF1877F2)),
                              SizedBox(width: 4),
                              Text(
                                'Lời mời',
                                style: TextStyle(color: Color(0xFF1877F2)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Sắp xếp',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1877F2)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Truy cập thường xuyên nhất',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Tạo nhóm'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
              const Divider(),
              ...groups.map(
                (group) => Column(
                  children: [
                    ListTile(
                      leading: Image.network(
                        group.coverImageUrl.isNotEmpty
                            ? group.coverImageUrl
                            : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                        width: 50,
                        height: 50,
                      ),
                      title: Text(group.name),
                      subtitle: Text(
                        '• ${group.description.isNotEmpty ? group.description : 'Hơn 25 bài viết mới'}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => GroupHomeScreen(groupId: group.id),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
