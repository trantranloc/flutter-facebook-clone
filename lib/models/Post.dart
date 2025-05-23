import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String name; // 👈 tên thật
  final String avatarUrl; // 👈 ảnh đại diện
  final String content;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final int likes;
  final int comments;
  final Map<String, int> reactionCounts;
  final String? reactionType;

  Post({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.reactionCounts,
    this.reactionType,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'],
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      reactionCounts: Map<String, int>.from(data['reactionCounts'] ?? {}),
      reactionType: null, // sẽ load riêng trong PostCard nếu cần
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'likes': likes,
      'comments': comments,
      'reactionCounts': {
        'like': 0,
        'love': 0,
        'care': 0,
        'haha': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      },
    };
  }
}
