import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_clone/client/screens/group/create_group_screen.dart';
import 'package:flutter_facebook_clone/client/screens/group/group_home_screen.dart';
import 'package:flutter_facebook_clone/models/group.dart';

class GroupHomeScreenOne extends StatefulWidget {
  const GroupHomeScreenOne({super.key});

  @override
  State<GroupHomeScreenOne> createState() => _GroupHomeScreenOneState();
}

class _GroupHomeScreenOneState extends State<GroupHomeScreenOne> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Group>> _fetchGroups() async {
    final user = _auth.currentUser;
    if (user == null) {
      return []; // Return empty list if user is not logged in
    }

    final snapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .get();

    // Also fetch groups where the user is the creator
    final creatorSnapshot = await _firestore
        .collection('groups')
        .where('creatorId', isEqualTo: user.uid)
        .get();

    // Combine and deduplicate the results
    final allDocs = [...snapshot.docs, ...creatorSnapshot.docs];
    final uniqueDocs = allDocs.fold<Map<String, QueryDocumentSnapshot>>(
      {},
      (map, doc) => map..[doc.id] = doc,
    ).values.toList();

    return uniqueDocs.map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  void _retryFetch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return FutureBuilder<List<Group>>(
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
                Text(
                  'Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _retryFetch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final groups = snapshot.data ?? [];

        if (user == null) {
          return const Center(
            child: Text(
              'Vui lòng đăng nhập để xem các nhóm',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        if (groups.isEmpty) {
          return const Center(
            child: Text(
              'Bạn chưa tham gia hoặc tạo nhóm nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView(
          children: [
            // Section Header: Truy cập thường xuyên nhất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nhóm của bạn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Sắp xếp',
                      style: TextStyle(
                        color: Color(0xFF1877F2),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Create Group Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Tạo nhóm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Group List
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8.0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        group.coverImageUrl.isNotEmpty
                            ? group.coverImageUrl
                            : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.group,
                              color: Colors.grey,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      group.description.isNotEmpty ? group.description : 'Hơn 25 bài viết mới',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupHomeScreen(groupId: group.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}