// lib/widgets/post_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/comment_screen.dart';

class PostCard extends StatefulWidget {
  final String username;
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
    required this.username,
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
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _localReaction = entry.key;
                                });
                                _animController.forward(from: 0);
                                widget.onReact?.call(entry.key);
                                _removeOverlay();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 150),
                                  tween: Tween(begin: 1.0, end: 1.0),
                                  builder:
                                      (context, scale, child) => MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          scale: 1.0,
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 26,
                                            ),
                                          ),
                                        ),
                                      ),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CommentScreen(
              username: widget.username,
              caption: widget.caption,
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
              children: const [
                Text(
                  "Chia sẻ bài viết",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Chia sẻ ngay bây giờ'),
                ),
                ListTile(
                  leading: Icon(Icons.send),
                  title: Text('Gửi qua tin nhắn'),
                ),
                ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Sao chép liên kết'),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        widget.username,
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
            Text(
              widget.caption,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 10),
            if (widget.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(widget.imageUrl, fit: BoxFit.cover),
              ),
            if (widget.reactionCounts != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildReactionSummary(widget.reactionCounts!),
              ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  key: _likeKey,
                  onTap: _showOverlayReaction,
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
                          widget.likes.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openCommentSection,
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
