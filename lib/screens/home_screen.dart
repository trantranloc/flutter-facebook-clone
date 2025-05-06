// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> posts = [
    {
      'username': 'Rosse',
      'time': '1 ngày trước',
      'caption': 'Hi ca nha !',
      'imageUrl':
          'https://cdn2.tuoitre.vn/471584752817336320/2024/4/16/img9704-17132420881631571916713.jpeg',
      'likes': 1045,
      'comments': 1258,
      'shares': 539,
    },
    {
      'username': 'IT Viet',
      'time': '1 ngày trước',
      'caption': 'Hoc Hanh',
      'imageUrl':
          'https://images.unsplash.com/photo-1603791440384-56cd371ee9a7',
      'likes': 23459,
      'comments': 17069,
      'shares': 19854,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  posts.insert(0, result);
                });
              }
            },
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
                            'https://i.imgur.com/your-avatar-url.jpg',
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
                              color: Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              ' Bạn đang nghĩ gì thế?',
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
                          label: 'Cảm xúc/hoạt động',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...posts
              .map(
                (post) => PostCard(
                  username: post['username'],
                  time: post['time'],
                  caption: post['caption'],
                  imageUrl: post['imageUrl'],
                  likes: post['likes'],
                  comments: post['comments'],
                  shares: post['shares'],
                ),
              )
              .toList(),
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
