import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Story.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  late Timer _timer;
  int _currentIndex = 0;
  double _progress = 0.0;
  bool _isPaused = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _checkAccessAndIncrementView();
    _startTimer();
  }

  Future<bool> _hasAccessToStory(Story story) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    if (story.userId == currentUserId) return true; // Chủ story luôn có quyền

    final userDoc =
        await _firestore.collection('users').doc(story.userId).get();
    final userData = userDoc.data();
    if (userData == null) return false;

    final List<dynamic> friends = userData['friends'] ?? [];
    final List<dynamic> closeFriends = userData['closeFriends'] ?? [];

    return friends.contains(currentUserId) ||
        closeFriends.contains(currentUserId);
  }

  void _checkAccessAndIncrementView() async {
    final story = widget.stories[_currentIndex];
    if (story.id == null || story.id!.isEmpty) return; // Preview mode

    if (!await _hasAccessToStory(story)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền xem story này.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    _incrementViewCount(story);
  }

  void _startTimer() {
    if (_isPaused) return;
    setState(() {
      _progress = 0.0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused) {
        setState(() {
          _progress += 0.02;
          if (_progress >= 1) {
            _progress = 1;
            timer.cancel();
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _checkAccessAndIncrementView();
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final dx = details.globalPosition.dx;
    if (dx < constraints.maxWidth / 2) {
      if (_currentIndex > 0) {
        _currentIndex--;
        _pageController.jumpToPage(_currentIndex);
        _checkAccessAndIncrementView();
        _timer.cancel();
        _startTimer();
      }
    } else {
      _timer.cancel();
      _nextStory();
    }
  }

  void _onLongPressStart() {
    setState(() {
      _isPaused = true;
    });
    _timer.cancel();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  Future<void> _incrementViewCount(Story story) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || story.id == null || story.id!.isEmpty) return;

    final storyRef = _firestore.collection('stories').doc(story.id);
    final storyDoc = await storyRef.get();
    final data = storyDoc.data();
    if (data == null) return;

    final viewedBy = List<String>.from(data['viewedBy'] ?? []);
    if (!viewedBy.contains(currentUser.uid)) {
      await storyRef.update({
        'views': FieldValue.increment(1),
        'viewedBy': FieldValue.arrayUnion([currentUser.uid]),
      });

      final senderDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final senderData = senderDoc.data();
      if (senderData != null) {
        final senderName = senderData['name'] ?? 'Người dùng';
        final senderAvatarUrl =
            senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

        await _firestore.collection('notifications').add({
          'userId': storyDoc['userId'],
          'senderId': currentUser.uid,
          'senderName': senderName,
          'senderAvatarUrl': senderAvatarUrl,
          'action': 'đã xem story của bạn.',
          'type': 'story_view',
          'storyId': story.id,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          'date': 'Hôm nay',
          'story': story.toMap(),
        });
      }
    }
  }

  Future<void> _toggleLike(Story story) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || story.id == null || story.id!.isEmpty) return;

    if (!await _hasAccessToStory(story)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền tương tác với story này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final storyRef = _firestore.collection('stories').doc(story.id);
    final storyDoc = await storyRef.get();
    final data = storyDoc.data();
    if (data == null) return;

    List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
    bool hasLiked = likedBy.contains(currentUser.uid);

    if (hasLiked) {
      likedBy.remove(currentUser.uid);
      await storyRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': likedBy,
      });
      final notificationSnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: storyDoc['userId'])
              .where('senderId', isEqualTo: currentUser.uid)
              .where('type', isEqualTo: 'story_like')
              .where('storyId', isEqualTo: story.id)
              .get();
      for (var doc in notificationSnapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      likedBy.add(currentUser.uid);
      await storyRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': likedBy,
      });

      final senderDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final senderData = senderDoc.data();
      if (senderData != null) {
        final senderName = senderData['name'] ?? 'Người dùng';
        final senderAvatarUrl =
            senderData['avatarUrl'] ?? 'https://i.pravatar.cc/avatars';
        await _firestore.collection('notifications').add({
          'userId': storyDoc['userId'],
          'senderId': currentUser.uid,
          'senderName': senderName,
          'senderAvatarUrl': senderAvatarUrl,
          'action': 'đã thích story của bạn.',
          'type': 'story_like',
          'storyId': story.id,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          'date': 'Hôm nay',
          'story': story.toMap(),
        });
      }
    }

    setState(() {});
  }

  void _showViewers(String storyId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final storyDoc = await _firestore.collection('stories').doc(storyId).get();
    final storyData = storyDoc.data();
    if (storyData == null || storyData['userId'] != currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ chủ story có thể xem danh sách người xem.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('stories').doc(storyId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final views = data?['views'] ?? 0;
              final viewedByIds = List<String>.from(data?['viewedBy'] ?? []);

              return Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lượt xem: $views',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child:
                          viewedByIds.isEmpty
                              ? const Center(
                                child: Text('Chưa có ai xem story này.'),
                              )
                              : FutureBuilder<List<Map<String, dynamic>>>(
                                future: _fetchViewerDetails(viewedByIds),
                                builder: (context, futureSnapshot) {
                                  if (!futureSnapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final viewers = futureSnapshot.data!;
                                  return ListView.builder(
                                    itemCount: viewers.length,
                                    itemBuilder: (context, index) {
                                      final viewer = viewers[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            viewer['avatarUrl'],
                                          ),
                                        ),
                                        title: Text(
                                          viewer['name'],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchViewerDetails(
    List<String> userIds,
  ) async {
    final List<Map<String, dynamic>> viewers = [];
    for (final userId in userIds) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null) {
        viewers.add({
          'name': userData['name'] ?? 'Người dùng',
          'avatarUrl': userData['avatarUrl'] ?? 'https://i.pravatar.cc/avatars',
        });
      }
    }
    return viewers;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _onTapDown(details, constraints),
                onLongPressStart: (_) => _onLongPressStart(),
                onLongPressEnd: _onLongPressEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(story.imageUrl),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: List.generate(widget.stories.length, (i) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        i == _currentIndex
                                            ? _progress
                                            : (i < _currentIndex ? 1 : 0),
                                    backgroundColor: Colors.grey[800],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(story.avatarUrl),
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.user,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showViewers(story.id!),
                                child: Text(
                                  _formatTimeAgo(story.time),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    if (story.caption != null && story.caption!.isNotEmpty)
                      Positioned(
                        bottom: 120,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            story.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (story.sticker != null && story.stickerOffset != null)
                      Positioned(
                        left: story.stickerOffset!.dx,
                        top: story.stickerOffset!.dy,
                        child: Text(
                          story.sticker!,
                          style: const TextStyle(
                            fontSize: 60,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child:
                          (story.id != null && story.id!.isNotEmpty)
                              ? StreamBuilder<DocumentSnapshot>(
                                stream:
                                    _firestore
                                        .collection('stories')
                                        .doc(story.id)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>;
                                  final likes = data['likes'] ?? 0;
                                  final views = data['views'] ?? 0;
                                  final likedBy = List<String>.from(
                                    data['likedBy'] ?? [],
                                  );
                                  final hasLiked = likedBy.contains(
                                    _auth.currentUser?.uid,
                                  );

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              hasLiked
                                                  ? FontAwesomeIcons.solidHeart
                                                  : FontAwesomeIcons.heart,
                                              color:
                                                  hasLiked
                                                      ? Colors.red
                                                      : Colors.white,
                                              size: 28,
                                            ),
                                            onPressed: () => _toggleLike(story),
                                          ),
                                          Text(
                                            '$likes',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            FontAwesomeIcons.eye,
                                            color: Colors.white,
                                            size: 25,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$views',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    print('Loading image: $imageUrl');
    if (imageUrl.startsWith('/')) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image $imageUrl: $error');
          return const Center(
            child: Icon(Icons.error, color: Colors.red, size: 48),
          );
        },
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder:
          (context, child, progress) =>
              progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image $imageUrl: $error');
        return const Center(
          child: Icon(Icons.error, color: Colors.red, size: 48),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
