import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../client/screens/comment_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_clone/providers/user_provider.dart';
import '../client/screens/profile_screen.dart';
import '../client/screens/create_post_screen.dart';
import '../models/Post.dart';

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
  final String? sharedFromPostId;
  final String? sharedFromUserName;
  final String? sharedFromAvatarUrl;
  final String? sharedFromContent;
  final List<String>? sharedFromImageUrls;

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
    this.sharedFromPostId,
    this.sharedFromUserName,
    this.sharedFromAvatarUrl,
    this.sharedFromContent,
    this.sharedFromImageUrls,
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

  Future<void> _shareToProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.userModel;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'content': 'Đã chia sẻ một bài viết',
        'imageUrls': [],
        'createdAt': Timestamp.now(),
        'likes': 0,
        'comments': 0,
        'reactionCounts': {
          'like': 0,
          'love': 0,
          'care': 0,
          'haha': 0,
          'wow': 0,
          'sad': 0,
          'angry': 0,
        },
        'sharedPostId': widget.postId,
      });

      if (mounted) {
        Navigator.pop(context); // Đóng sheet nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ bài viết về trang cá nhân.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi chia sẻ: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _popupController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleReactionWithToggle(String tappedReaction) async {
    final user = Provider.of<UserProvider>(context, listen: false).userModel;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final userId = user.uid;

    final oldReaction = _userReaction;

    if (oldReaction == tappedReaction) {
      // Bỏ cảm xúc
      setState(() {
        if (_reactionCounts.containsKey(oldReaction)) {
          final currentCount = _reactionCounts[oldReaction]!;
          _reactionCounts[oldReaction!] =
              (currentCount > 0 ? currentCount - 1 : 0);
        }
        _userReaction = null;
      });

      await postRef.update({
        'reactionCounts.$oldReaction': FieldValue.increment(-1),
      });

      await postRef.collection('reactions').doc(userId).delete();
      return;
    }

    // Gán cảm xúc mới
    setState(() {
      if (oldReaction != null && oldReaction != tappedReaction) {
        _reactionCounts[oldReaction] = (_reactionCounts[oldReaction] ?? 1) - 1;
      }
      _reactionCounts[tappedReaction] =
          (_reactionCounts[tappedReaction] ?? 0) + 1;
      _userReaction = tappedReaction;
    });

    await postRef.update({
      'reactionCounts.$tappedReaction': FieldValue.increment(1),
      if (oldReaction != null && oldReaction != tappedReaction)
        'reactionCounts.$oldReaction': FieldValue.increment(-1),
    });

    await postRef.collection('reactions').doc(userId).set({
      'type': tappedReaction,
    });
  }

  void _showOverlayReaction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _likeKey.currentContext?.findRenderObject() as RenderBox?;
      final overlay = Overlay.of(context);
      if (box == null || overlay == null) return;

      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;

      _popupController.forward(from: 0);
      _dismissTimer?.cancel();

      _overlayEntry = OverlayEntry(
        builder: (context) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: Stack(
              children: [
                Positioned(
                  left: offset.dx + size.width / 2 - 150, // căn giữa
                  top: offset.dy - 80,
                  child: ScaleTransition(
                    scale: _popupAnim,
                    child: MouseRegion(
                      onEnter: (_) => _dismissTimer?.cancel(),
                      onExit: (_) => _startAutoDismiss(),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(blurRadius: 6, color: Colors.black26),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                reactionIcons.entries.map((entry) {
                                  return GestureDetector(
                                    onTap: () {
                                      _handleReactionWithToggle(entry.key);
                                      _removeOverlay();
                                    },
                                    child: AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      scale:
                                          _userReaction == entry.key
                                              ? 1.3
                                              : 1.0,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              reactionTexts[entry.key]!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
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
              ],
            ),
          );
        },
      );

      overlay.insert(_overlayEntry!);
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
                  title: const Text('Chia sẽ về trang cá nhân'),
                  onTap: () {
                    _shareToProfile();
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
                        builder:
                            (_) => ProfileScreen(
                              uid: widget.userId,
                              hideAppBar: true,
                            ),
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
                    Provider.of<UserProvider>(context, listen: false);

                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      builder: (context) {
                        final isOwnPost =
                            FirebaseAuth.instance.currentUser?.uid ==
                            widget.userId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Thanh kéo
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              if (isOwnPost) ...[
                                // Tùy chọn cho bài viết của người dùng hiện tại
                                ListTile(
                                  leading: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  title: const Text('Sửa bài viết'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final editedPost = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CreatePostScreen(
                                              post: Post(
                                                id: widget.postId,
                                                userId: widget.userId,
                                                name: widget.name,
                                                avatarUrl:
                                                    widget.avatarUrl ?? '',
                                                content: widget.caption,
                                                imageUrls:
                                                    widget.imageUrl.isNotEmpty
                                                        ? [widget.imageUrl]
                                                        : [],
                                                createdAt:
                                                    Timestamp.now(), // hoặc giữ nguyên nếu bạn có field gốc
                                                likes: widget.likes,
                                                comments: widget.comments,
                                                reactionCounts:
                                                    widget.reactionCounts ?? {},
                                              ),
                                            ),
                                      ),
                                    );
                                    if (editedPost != null) {
                                      // Gọi callback để HomeScreen làm mới bài viết
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cập nhật thành công',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text('Xóa bài viết'),
                                  onTap: () async {
                                    Navigator.pop(context); // Đóng bottom sheet
                                    // Xác nhận trước khi xóa
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Xóa bài viết'),
                                            content: const Text(
                                              'Bạn có chắc muốn xóa bài viết này?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text('Hủy'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // Xóa bài viết khỏi Firestore
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(widget.postId)
                                            .delete();
                                        Navigator.pop(context);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Xóa bài viết thành công',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi khi xóa bài viết: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ] else ...[
                                // Tùy chọn cho bài viết của người khác
                                ListTile(
                                  leading: const Icon(
                                    Icons.report,
                                    color: Colors.red,
                                  ),
                                  title: const Text('Báo cáo bài viết'),
                                  onTap: () async {
                                    Navigator.pop(context); // Đóng bottom sheet
                                    // Logic báo cáo bài viết
                                    final reason = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              'Báo cáo bài viết',
                                            ),
                                            content: const Text(
                                              'Vui lòng chọn lý do báo cáo:',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      'Nội dung không phù hợp',
                                                    ),
                                                child: const Text(
                                                  'Nội dung không phù hợp',
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      'Spam',
                                                    ),
                                                child: const Text('Spam'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      'Khác',
                                                    ),
                                                child: const Text('Khác'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('Hủy'),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (reason != null && reason.isNotEmpty) {
                                      try {
                                        // Lưu báo cáo vào Firestore
                                        await FirebaseFirestore.instance
                                            .collection('reports')
                                            .add({
                                              'postId': widget.postId,
                                              'userId':
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid,
                                              'reason': reason,
                                              'timestamp': Timestamp.now(),
                                            });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Báo cáo đã được gửi',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi khi gửi báo cáo: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.share,
                                    color: Colors.blue,
                                  ),
                                  title: const Text('Chia sẻ bài viết'),
                                  onTap: () {
                                    Navigator.pop(context); // Đóng bottom sheet
                                    // Logic chia sẻ bài viết
                                    Share.share(
                                      'Xem bài viết: https://yourapp.com/post/${widget.postId}',
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  title: const Text('Ẩn bài viết'),
                                  onTap: () async {
                                    Navigator.pop(context); // Đóng bottom sheet
                                    // Logic ẩn bài viết (lưu vào danh sách ẩn của người dùng)
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid,
                                          )
                                          .collection('hidden_posts')
                                          .doc(widget.postId)
                                          .set({
                                            'postId': widget.postId,
                                            'timestamp': Timestamp.now(),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã ẩn bài viết'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Lỗi khi ẩn bài viết: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.bookmark,
                                    color: Colors.green,
                                  ),
                                  title: const Text('Lưu bài viết'),
                                  onTap: () async {
                                    Navigator.pop(context); // Đóng bottom sheet
                                    // Logic lưu bài viết
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid,
                                          )
                                          .collection('saved_posts')
                                          .doc(widget.postId)
                                          .set({
                                            'postId': widget.postId,
                                            'timestamp': Timestamp.now(),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã lưu bài viết'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Lỗi khi lưu bài viết: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              const SizedBox(
                                height: 10,
                              ), // Khoảng cách dưới cùng
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nếu là bài chia sẻ
            if (widget.sharedFromPostId != null) ...[
              if (widget.caption.isNotEmpty)
                Text(widget.caption, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 10),

              // Khung bài viết được chia sẻ
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header người đăng bài gốc
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              widget.sharedFromAvatarUrl != null
                                  ? NetworkImage(widget.sharedFromAvatarUrl!)
                                  : const AssetImage(
                                        'assets/avatar_placeholder.png',
                                      )
                                      as ImageProvider,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.sharedFromUserName ?? 'Người dùng',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Nội dung bài gốc
                    if ((widget.sharedFromContent ?? '').isNotEmpty)
                      Text(
                        widget.sharedFromContent!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Ảnh bài gốc (nếu có)
                    if ((widget.sharedFromImageUrls?.isNotEmpty ?? false))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.sharedFromImageUrls!.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Bài viết bình thường
              if (widget.caption.isNotEmpty)
                Text(widget.caption, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 10),

              if (widget.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(widget.imageUrl, fit: BoxFit.cover),
                ),
            ],

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
                  onTap: () {
                    _animController.forward(from: 0); // hiệu ứng nhấn mềm
                    _handleReactionWithToggle('like');
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact(); // rung nhẹ khi long press
                    _showOverlayReaction();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        if (_userReaction != null) ...[
                          Text(
                            reactionIcons[_userReaction]!,
                            style: TextStyle(
                              fontSize: 24,
                              color: reactionColors[_userReaction]!,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 1,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reactionTexts[_userReaction!]!,
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
