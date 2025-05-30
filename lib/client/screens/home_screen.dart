import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'create_post_screen.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';
import '../../widgets/post_card.dart';
import '../../models/Story.dart';
import '../../models/Post.dart';
import '../../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

String timeAgo(Timestamp timestamp) {
  final now = DateTime.now();
  final postTime = timestamp.toDate();
  final diff = now.difference(postTime);

  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${postTime.day}/${postTime.month}/${postTime.year}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> posts = [];
  List<Story> stories = [];
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchPosts();
    fetchStory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        userProvider.loadUserData(userId, _userService);
      }
    });
  }

  Future<List<String>> fetchFriendIds(String currentUserId) async {
    final friendSnap1 =
        await FirebaseFirestore.instance
            .collection('friends')
            .where('status', isEqualTo: 'accepted')
            .where('userId1', isEqualTo: currentUserId)
            .get();

    final friendSnap2 =
        await FirebaseFirestore.instance
            .collection('friends')
            .where('status', isEqualTo: 'accepted')
            .where('userId2', isEqualTo: currentUserId)
            .get();

    List<String> friendIds = [];

    for (var doc in friendSnap1.docs) {
      friendIds.add(doc['userId2']);
    }

    for (var doc in friendSnap2.docs) {
      friendIds.add(doc['userId1']);
    }

    return friendIds;
  }

  Future<void> fetchStory() async {
    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // Nếu không đăng nhập, thoát

      // Lấy thông tin người dùng hiện tại
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final userData = userDoc.data();
      if (userData == null) return;

      // final List<dynamic> friends = userData['friends'] ?? [];
      // final List<dynamic> closeFriends = userData['closeFriends'] ?? [];

      // Lấy tất cả stories
      final snapshot =
          await FirebaseFirestore.instance
              .collection('stories')
              .orderBy('time', descending: true)
              .get();

      final List<Story> loaded = [];
      for (var doc in snapshot.docs) {
        final story = Story.fromDocument(doc);
        final expiresAt = (doc['expiresAt'] as Timestamp).toDate();
        final storyOwnerId = story.userId;

        // Kiểm tra nếu story đã hết hạn
        if (now.isAfter(expiresAt)) {
          await FirebaseFirestore.instance
              .collection('stories')
              .doc(doc.id)
              .update({'isActive': false});
          continue;
        }

        // Kiểm tra quyền xem story
        if (doc['isActive'] == true) {
          if (storyOwnerId == userId) {
            // Story của chính người dùng
            loaded.add(story);
          } else {
            // Kiểm tra xem người dùng hiện tại có trong danh sách bạn bè hoặc bạn thân của chủ story
            final storyOwnerDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(storyOwnerId)
                    .get();
            final storyOwnerData = storyOwnerDoc.data();
            if (storyOwnerData != null) {
              final List<dynamic> ownerFriends =
                  storyOwnerData['friends'] ?? [];
              final List<dynamic> ownerCloseFriends =
                  storyOwnerData['closeFriends'] ?? [];
              if (ownerFriends.contains(userId) ||
                  ownerCloseFriends.contains(userId)) {
                loaded.add(story);
              }
            }
          }
        }
      }

      setState(() {
        stories = loaded;
      });
    } catch (e) {
      print('Error fetching stories: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải story: $e')));
    }
  }

  Future<void> fetchPosts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Lấy danh sách bạn bè từ trường `friends` của user hiện tại
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final userData = currentUserDoc.data();
      final List<String> friendIds = List<String>.from(
        userData?['friends'] ?? [],
      );

      // Thêm bài viết của chính người dùng
      friendIds.add(currentUser.uid);

      // Do Firestore giới hạn 10 phần tử trong `whereIn`, nên chia nhỏ
      List<Post> allPosts = [];
      const int chunkSize = 10;
      for (int i = 0; i < friendIds.length; i += chunkSize) {
        final chunk = friendIds.sublist(
          i,
          (i + chunkSize > friendIds.length) ? friendIds.length : i + chunkSize,
        );

        final snapshot =
            await FirebaseFirestore.instance
                .collection('posts')
                .where('userId', whereIn: chunk)
                .orderBy('createdAt', descending: true)
                .get();

        final chunkPosts = await Future.wait(
          snapshot.docs.map((doc) => Post.fromDocumentWithShare(doc)),
        );

        allPosts.addAll(chunkPosts);
      }

      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        posts = allPosts;
      });
    } catch (e) {
      print('Error fetching posts for friends: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải bài viết bạn bè: $e')),
      );
    }
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (result != null && result is Post) {
      setState(() {
        posts.insert(0, result);
      });
      await fetchPosts(); // Làm mới bài viết
    }
  }

  Future<void> _navigateToCreateStory() async {
    final newStory = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (newStory != null && newStory is Story) {
      setState(() {
        stories.insert(0, newStory);
      });
      await fetchStory(); // Làm mới stories
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    const defaultAvatar = 'https://i.pravatar.cc/150?img=5';
    return Scaffold(
      body: ListView(
        children: [
          // Story Section
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: stories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _navigateToCreateStory,
                        child: _buildCreateStoryCard(),
                      );
                    }
                    final story = stories[index - 1];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => StoryViewScreen(
                                  stories: stories,
                                  initialIndex: index - 1,
                                ),
                          ),
                        );
                      },
                      child: _buildStoryItem(story),
                    );
                  },
                ),
                if (stories.length > 5)
                  Positioned(
                    right: 8,
                    top: 50,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => StoryViewScreen(
                                  stories: stories,
                                  initialIndex: 0,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF1877F2),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Create Post Section
          GestureDetector(
            onTap: _navigateToCreatePost,
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  userProvider.userModel?.avatarUrl ??
                                  defaultAvatar,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Bạn đang nghĩ gì thế?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _ActionButton(
                          icon: Icons.videocam,
                          color: Colors.red,
                          label: 'Video trực tiếp',
                        ),
                        _ActionButton(
                          icon: Icons.photo,
                          color: Colors.green,
                          label: 'Ảnh/video',
                        ),
                        _ActionButton(
                          icon: Icons.emoji_emotions,
                          color: Colors.orange,
                          label: 'Cảm xúc',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Posts from Firestore
          ...posts.map(
            (post) => PostCard(
              userId: post.userId,
              postId: post.id,
              name: post.name,
              avatarUrl: post.avatarUrl,
              time: timeAgo(post.createdAt),
              caption: post.content,
              imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
              likes: post.likes,
              comments: post.comments,
              shares: 0,
              reactionCounts: post.reactionCounts,
              reactionType: post.reactionType,
              sharedFromPostId: post.sharedPostId,
              sharedFromUserName: post.sharedFromUserName,
              sharedFromAvatarUrl: post.sharedFromAvatarUrl,
              sharedFromContent: post.sharedFromContent,
              sharedFromImageUrls: post.sharedFromImageUrls,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    final userProvider = Provider.of<UserProvider>(context);
    const defaultAvatar = 'https://i.pravatar.cc/150?img=5';
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[100],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: userProvider.userModel?.avatarUrl ?? defaultAvatar,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => const CircularProgressIndicator(),
                errorWidget:
                    (context, url, error) =>
                        const Icon(Icons.person, size: 30, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo Story',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    print('Loading story image: ${story.imageUrl}'); // Log để debug
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            story.imageUrl.startsWith('/')
                ? Image.file(
                  File(story.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      'Error loading local image ${story.imageUrl}: $error',
                    );
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      ),
                    );
                  },
                )
                : Image.network(
                  story.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder:
                      (context, child, loadingProgress) =>
                          loadingProgress == null
                              ? child
                              : const Center(
                                child: CircularProgressIndicator(),
                              ),
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      'Error loading network image ${story.imageUrl}: $error',
                    );
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      ),
                    );
                  },
                ),
            Positioned(
              top: 8,
              left: 8,
              child: CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(story.avatarUrl),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                story.user,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
