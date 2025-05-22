import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../client/screens/comment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import '../client/screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String name;
  final String time;
  final String caption;
  final String imageUrl;
  final String? avatarUrl;
  final int likes;
  final int comments;
  final int shares;
  final String? reactionType;
  final Map<String, int>? reactionCounts;
  final void Function(String)? onReact;
  final String userId;

  const PostCard({
    super.key,
    required this.postId,
    required this.name,
    required this.time,
    required this.caption,
    required this.imageUrl,
    this.avatarUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.reactionType,
    this.reactionCounts,
    this.onReact,
    required this.userId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeKey = GlobalKey();
  Map<String, int> _reactionCounts = {};
  String? _userReaction;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late AnimationController _popupController;
  late Animation<double> _popupAnim;
  Timer? _dismissTimer;

  final Map<String, String> reactionIcons = {
    'like': '👍',
    'love': '❤️',
    'care': '🤗',
    'haha': '😆',
    'wow': '😲',
    'sad': '😢',
    'angry': '😡',
  };

  final Map<String, String> reactionTexts = {
    'like': 'Thích',
    'love': 'Yêu thích',
    'care': 'Thương thương',
    'haha': 'Haha',
    'wow': 'Wow',
    'sad': 'Buồn',
    'angry': 'Phẫn nộ',
  };

  final Map<String, Color> reactionColors = {
    'like': Colors.blue,
    'love': Colors.red,
    'care': Colors.orange,
    'haha': Colors.amber,
    'wow': Colors.purple,
    'sad': Colors.indigo,
    'angry': Colors.deepOrange,
  };

  @override
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_animController);

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _popupAnim = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutBack,
    );

    _loadReaction();
  }

  Future<void> _loadReaction() async {
    final user = Provider.of<UserProvider>(context, listen: false).userModel;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final doc = await postRef.get();

    final data = doc.data();
    if (data != null && data['reactionCounts'] != null) {
      setState(() {
        _reactionCounts = Map<String, int>.from(data['reactionCounts']);
      });
    }

    final reactionDoc =
        await postRef.collection('reactions').doc(user.uid).get();
    if (reactionDoc.exists) {
      setState(() {
        _userReaction = reactionDoc['type'];
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _popupController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleReaction(String newReaction) async {
    final user = Provider.of<UserProvider>(context, listen: false).userModel;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final userId = user.uid;

    final oldReaction = _userReaction;

    setState(() {
      if (oldReaction != null) {
        _reactionCounts[oldReaction] = (_reactionCounts[oldReaction] ?? 1) - 1;
      }
      _reactionCounts[newReaction] = (_reactionCounts[newReaction] ?? 0) + 1;
      _userReaction = newReaction;
    });

    await postRef.update({
      'reactionCounts.$newReaction': FieldValue.increment(1),
      if (oldReaction != null && oldReaction != newReaction)
        'reactionCounts.$oldReaction': FieldValue.increment(-1),
    });

    await postRef.collection('reactions').doc(userId).set({
      'type': newReaction,
    });
  }

  void _showOverlayReaction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _likeKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        print("⚠️ Không tìm thấy RenderBox của _likeKey");
        return;
      }

      final overlayBox =
          Overlay.of(context)?.context.findRenderObject() as RenderBox?;
      if (overlayBox == null) return;

      final offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);

      _popupController.forward(from: 0);

      _overlayEntry = OverlayEntry(
        builder:
            (context) => Positioned(
              left: offset.dx - 20,
              top: offset.dy - 60,
              child: Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: _popupAnim,
                  child: MouseRegion(
                    onEnter: (_) => _dismissTimer?.cancel(),
                    onExit: (_) => _startAutoDismiss(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            reactionIcons.entries.map((entry) {
                              return InkWell(
                                onTap: () {
                                  _handleReaction(entry.key);
                                  _removeOverlay();
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      _startAutoDismiss();
    });
  }

  void _startAutoDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), _removeOverlay);
  }

  void _removeOverlay() {
    _popupController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _dismissTimer?.cancel();
  }

  void _editPost() {
    final TextEditingController editController = TextEditingController(
      text: widget.caption,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chỉnh sửa bài viết'),
            content: TextField(
              controller: editController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Nhập nội dung mới...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newCaption = editController.text.trim();
                  if (newCaption.isNotEmpty && newCaption != widget.caption) {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .update({'content': newCaption});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật bài viết')),
                    );
                    setState(
                      () {},
                    ); // Gợi ý: có thể cần load lại hoặc dùng Provider để cập nhật
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  void _openCommentSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserName = userProvider.userModel?.name ?? 'Ẩn danh';
    final currentAvatarUrl = userProvider.userModel?.avatarUrl ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: CommentScreen(
                    postId: widget.postId,
                    name: widget.name,
                    caption: widget.caption,
                    scrollController: scrollController,
                    currentUserName: currentUserName,
                    currentAvatarUrl: currentAvatarUrl,
                  ),
                ),
          ),
    );
  }

  void _sharePost() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chia sẻ bài viết",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Sao chép liên kết'),
                  onTap: () {
                    final postLink =
                        "https://yourapp.com/posts/${widget.postId}";

                    Clipboard.setData(ClipboardData(text: postLink));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã sao chép liên kết!")),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Chia sẻ qua ứng dụng khác'),
                  onTap: () {
                    Share.share("Xem bài viết: https://link.to/post");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildReactionSummary(Map<String, int> counts) {
    final sorted =
        counts.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topReactions =
        sorted.take(3).map((e) => reactionIcons[e.key]!).toList();
    final total = counts.values.fold(0, (sum, e) => sum + e);

    return Row(
      children: [
        ...topReactions.map(
          (e) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(e, style: const TextStyle(fontSize: 16)),
          ),
        ),
        Text('$total', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final String displayReaction = reactionIcons[_userReaction ?? 'like']!;

    // final totalLikes =
    _reactionCounts.values.fold(0, (sum, e) => sum + e);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(uid: widget.userId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        widget.avatarUrl != null
                            ? NetworkImage(widget.avatarUrl!)
                            : const AssetImage('assets/avatar_placeholder.png')
                                as ImageProvider,
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            widget.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.public,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  splashRadius: 20,
                  onPressed: () {
                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );
                    final isOwner =
                        userProvider.userModel?.uid == widget.userId;

                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        return Wrap(
                          children:
                              isOwner
                                  ? [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('Chỉnh sửa bài viết'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _editPost();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete),
                                      title: const Text('Xóa bài viết'),
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(widget.postId)
                                            .delete();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Đã xóa bài viết"),
                                          ),
                                        );
                                      },
                                    ),
                                  ]
                                  : [
                                    ListTile(
                                      leading: const Icon(Icons.share),
                                      title: const Text('Chia sẻ bài viết'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _sharePost();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.flag),
                                      title: const Text('Báo cáo bài viết'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Bài viết đã được báo cáo",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Caption
            Text(widget.caption, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 10),

            // Image
            if (widget.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(widget.imageUrl, fit: BoxFit.cover),
              ),

            // Reaction Summary
            if (_reactionCounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildReactionSummary(_reactionCounts),
              ),

            const Divider(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // LIKE
                GestureDetector(
                  key: _likeKey,
                  onTap: () => _handleReaction('like'),
                  onLongPress: () {
                    print("🟦 Long press triggered");
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showOverlayReaction();
                    });
                  },

                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Row(
                      children: [
                        if (_userReaction != null) ...[
                          Text(
                            reactionIcons[_userReaction]!,
                            style: TextStyle(
                              fontSize: 22,
                              color: reactionColors[_userReaction]!,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userReaction != null &&
                                    _reactionCounts[_userReaction] != null
                                ? '${_reactionCounts[_userReaction!]!} ${reactionTexts[_userReaction]!}'
                                : reactionTexts[_userReaction]!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: reactionColors[_userReaction]!,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 22,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Thích',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // COMMENT
                InkWell(
                  onTap: _openCommentSection,
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.comments > 0
                            ? '${widget.comments} bình luận'
                            : 'Bình luận',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // SHARE
                InkWell(
                  onTap: _sharePost,
                  child: Row(
                    children: [
                      const Icon(Icons.share_outlined, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.shares > 0
                            ? '${widget.shares} chia sẻ'
                            : 'Chia sẻ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
