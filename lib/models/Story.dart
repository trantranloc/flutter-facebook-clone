import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String? id;
  final String userId; // Bắt buộc, không nullable
  final String imageUrl;
  final String user;
  final String avatarUrl;
  final DateTime time;
  final DateTime expiresAt; // Thêm trường expiresAt
  final bool isActive; // Thêm trường isActive
  final String? caption;
  final String? sticker;
  final Offset? stickerOffset;
  final int likes;
  final int views;
  final List<String> likedBy;
  final List<String> viewedBy; // Thêm trường viewedBy

  Story({
    this.id,
    required this.userId,
    required this.imageUrl,
    required this.user,
    required this.avatarUrl,
    required this.time,
    required this.expiresAt,
    required this.isActive,
    this.caption,
    this.sticker,
    this.stickerOffset,
    this.likes = 0,
    this.views = 0,
    this.likedBy = const [],
    this.viewedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'user': user,
      'avatarUrl': avatarUrl,
      'time': Timestamp.fromDate(time),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'caption': caption,
      'sticker': sticker,
      'stickerOffsetX': stickerOffset?.dx,
      'stickerOffsetY': stickerOffset?.dy,
      'likes': likes,
      'views': views,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
    };
  }

  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      user: data['user'] ?? 'Unknown',
      avatarUrl: data['avatarUrl'] ?? 'https://via.placeholder.com/150',
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      caption: data['caption'],
      sticker: data['sticker'],
      stickerOffset:
          data['stickerOffsetX'] != null && data['stickerOffsetY'] != null
              ? Offset(
                (data['stickerOffsetX'] as num).toDouble(),
                (data['stickerOffsetY'] as num).toDouble(),
              )
              : null,
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }
}
