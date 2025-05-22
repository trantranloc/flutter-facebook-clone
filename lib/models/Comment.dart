// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String postId;
  final String content;
  final String userName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      userId: map['userId'],
      postId: map['postId'],
      userName: map['userName'] ?? '',
      content: map['content'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'content': content,
      'userName': userName,
      'createdAt': createdAt,
    };
  }
}
