import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../client/screens/comment_screen.dart';

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
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeKey = GlobalKey();
  String? _localReaction;
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

  @override
  void initState() {
    super.initState();
    _localReaction = widget.reactionType;
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
  }

  @override
  void dispose() {
    _animController.dispose();
    _popupController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleReaction(String newReaction) {
    setState(() {
      if (_localReaction != null &&
          widget.reactionCounts != null &&
          widget.reactionCounts!.containsKey(_localReaction)) {
        widget.reactionCounts![_localReaction!] =
            (widget.reactionCounts![_localReaction!] ?? 1) - 1;
      }
      if (widget.reactionCounts != null) {
        widget.reactionCounts![newReaction] =
            (widget.reactionCounts![newReaction] ?? 0) + 1;
      }

      _localReaction = newReaction;
    });

    _animController.forward(from: 0);
    widget.onReact?.call(newReaction);
    _removeOverlay();
  }

  void _showOverlayReaction() {
    final RenderBox box =
        _likeKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

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
                              onTap: () => _handleReaction(entry.key),
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

  void _openCommentSection() {
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
                    Clipboard.setData(
                      const ClipboardData(text: "https://link.to/post"),
                    );
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
    final String displayReaction = reactionIcons[_localReaction ?? 'like']!;
    final totalLikes =
        widget.reactionCounts?.values.fold(0, (sum, e) => sum + e) ??
        widget.likes;

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
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : const AssetImage('assets/avatar_placeholder.png')
                              as ImageProvider,
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
                  onPressed: () {},
                  splashRadius: 20,
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
            if (widget.reactionCounts != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildReactionSummary(widget.reactionCounts!),
              ),

            const Divider(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  key: _likeKey,
                  onTap: () => _handleReaction('like'),
                  onLongPress: _showOverlayReaction,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Row(
                      children: [
                        Text(
                          displayReaction,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          totalLikes.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openCommentSection,
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.comments.toString()),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _sharePost,
                  child: Row(
                    children: [
                      const Icon(Icons.share_outlined, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.shares.toString()),
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
