import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'create_post_screen.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';
import 'event_and_birthday_screen.dart';
import 'notification_screen.dart';
import '../widgets/post_card.dart';
import '../models/Story.dart';
import '../models/Post.dart'; // 👈 Thêm model Post

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
  List<Post> posts = [
    Post(
      id: '1',
      userId: 'user_rosse',
      content: 'Hi ca nha !',
      imageUrls: [
        'https://cdn2.tuoitre.vn/471584752817336320/2024/4/16/img9704-17132420881631571916713.jpeg',
      ],
      createdAt: Timestamp.now(),
      likes: 1045,
    ),
    Post(
      id: '2',
      userId: 'user_itviet',
      content: 'Hoc Hanh',
      imageUrls: [
        'https://images.unsplash.com/photo-1603791440384-56cd371ee9a7',
      ],
      createdAt: Timestamp.now(),
      likes: 23459,
    ),
  ];
  List<Story> stories = [
    Story(
      imageUrl: 'https://picsum.photos/200/300',
      user: 'Jane Smith',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      caption: 'Beautiful day!',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/301',
      user: 'John Doe',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      caption: 'Evening vibes',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/302',
      user: 'Anna Lee',
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      caption: 'Exploring the city',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/303',
      user: 'Mike Brown',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      time: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/304',
      user: 'Sarah Wilson',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      caption: 'Coffee time!',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/305',
      user: 'Tom Clark',
      avatarUrl: 'https://i.pravatar.cc/150?img=25',
      time: DateTime.now().subtract(const Duration(hours: 6)),
      caption: 'Nature lover',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/306',
      user: 'Emily Davis',
      avatarUrl: 'https://i.pravatar.cc/150?img=30',
      time: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/307',
      user: 'David Miller',
      avatarUrl: 'https://i.pravatar.cc/150?img=35',
      time: DateTime.now().subtract(const Duration(hours: 8)),
      caption: 'Sunset views',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/308',
      user: 'Laura Adams',
      avatarUrl: 'https://i.pravatar.cc/150?img=40',
      time: DateTime.now().subtract(const Duration(hours: 9)),
      caption: 'Chasing dreams',
    ),
    Story(
      imageUrl: 'https://picsum.photos/200/309',
      user: 'Chris Evans',
      avatarUrl: 'https://i.pravatar.cc/150?img=45',
      time: DateTime.now().subtract(const Duration(hours: 10)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .get();

    final List<Post> loaded =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();

    setState(() {
      posts = [
        ...[
          Post(
            id: '1',
            userId: 'user_rosse',
            content: 'Hi ca nha !',
            imageUrls: [
              'https://cdn2.tuoitre.vn/471584752817336320/2024/4/16/img9704-17132420881631571916713.jpeg',
            ],
            createdAt: Timestamp.now(),
            likes: 1045,
          ),
          Post(
            id: '2',
            userId: 'user_itviet',
            content: 'Hoc Hanh',
            imageUrls: [
              'https://images.unsplash.com/photo-1603791440384-56cd371ee9a7',
            ],
            createdAt: Timestamp.now(),
            likes: 23459,
          ),
        ],
        ...loaded,
      ];
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=5',
                          ),
                          radius: 22,
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

          // Notifications
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.bell,
                color: Color(0xFF1877F2),
              ),
              title: const Text('Thông báo'),
              subtitle: const Text('Xem các thông báo mới nhất'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
          ),

          // Events
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.cakeCandles,
                color: Color(0xFF1877F2),
              ),
              title: const Text('Sự kiện & Sinh nhật'),
              subtitle: const Text('Xem các sự kiện và sinh nhật sắp tới'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventAndBirthdayScreen(),
                  ),
                );
              },
            ),
          ),

          // Posts from Firestore
          ...posts.map(
            (post) => PostCard(
              postId: post.id,
              username: post.userId, // giả sử userId là tên người dùng demo
              time: timeAgo(
                post.createdAt,
              ), // bạn có thể định dạng từ post.createdAt
              caption: post.content,
              imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
              likes: post.likes,
              comments: 0,
              shares: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard() {
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
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
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
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(story.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
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
