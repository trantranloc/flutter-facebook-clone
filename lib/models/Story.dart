import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String? id;
  final String imageUrl;
  final String user;
  final String avatarUrl;
  final DateTime time;
  final String caption; 
  final String? sticker;
  final Offset? stickerOffset;

  Story({
    this.id,
    required this.imageUrl,
    required this.user,
    required this.avatarUrl,
    required this.time,
    this.caption = '', 
    this.sticker,
    this.stickerOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'user': user,
      'avatarUrl': avatarUrl,
      'time': Timestamp.fromDate(time),
      'caption': caption,
      'sticker': sticker,
      'stickerOffsetX': stickerOffset?.dx,
      'stickerOffsetY': stickerOffset?.dy,
    };
  }

  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      user:
          data['userName'] ??
          data['user'] ??
          'Unknown',
      avatarUrl:
          data['userAvatar'] ??
          data['avatarUrl'] ??
          'https://via.placeholder.com/150',
      time:
          (data['createdAt'] ?? data['time'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      caption: data['caption'] ?? '',
      sticker: data['sticker'],
      stickerOffset:
          data['stickerOffsetX'] != null && data['stickerOffsetY'] != null
              ? Offset(
                (data['stickerOffsetX'] as num).toDouble(),
                (data['stickerOffsetY'] as num).toDouble(),
              )
              : null,
    );
  }
}
