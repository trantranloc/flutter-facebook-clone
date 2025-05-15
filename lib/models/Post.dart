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

  Post({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.likes,
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
    };
  }
}
