import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String? id;
  final String imageUrl;
  final String user;
  final String avatarUrl;
  final DateTime time;
  final String? caption;
  final String? sticker;
  final Offset? stickerOffset;

  Story({
    this.id,
    required this.imageUrl,
    required this.user,
    required this.avatarUrl,
    required this.time,
    this.caption,
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
      'stickerOffset': stickerOffset != null
          ? {'dx': stickerOffset!.dx, 'dy': stickerOffset!.dy}
          : null,
    };
  }

  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      imageUrl: data['imageUrl'],
      user: data['user'],
      avatarUrl: data['avatarUrl'],
      time: (data['time'] as Timestamp).toDate(),
      caption: data['caption'],
      sticker: data['sticker'],
      stickerOffset: data['stickerOffset'] != null
          ? Offset(
              data['stickerOffset']['dx'],
              data['stickerOffset']['dy'],
            )
          : null,
    );
  }
}