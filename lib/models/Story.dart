import 'package:flutter/material.dart';

class Story {
  final String imageUrl;
  final String user;
  final String avatarUrl;
  final DateTime time;
  final String? caption;
  final String? sticker;
  final Offset? stickerOffset;

  Story({
    required this.imageUrl,
    required this.user,
    required this.avatarUrl,
    required this.time,
    this.caption,
    this.sticker,
    this.stickerOffset,
  });
}
