import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/comment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String name;
  final String caption;
  final ScrollController scrollController;
  final String currentUserName;
  final String currentAvatarUrl;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.name,
    required this.caption,
    required this.scrollController,
    required this.currentUserName,
    required this.currentAvatarUrl,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  int? _replyingToIndex;
  bool _isEditing = false;
  String? _editingCommentId;
  final Map<int, bool> _showAllReplies = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final data = await _commentService.loadComments(widget.postId);
    setState(() => _comments = data);
  }

  String formatTime(Timestamp timestamp) {
    final time = timestamp.toDate();
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }

  Future<void> _addOrUpdateComment(String text) async {
    if (text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_isEditing && _editingCommentId != null) {
      await _commentService.updateComment(
        widget.postId,
        _editingCommentId!,
        text,
      );
      _isEditing = false;
      _editingCommentId = null;
    } else if (_replyingToIndex != null) {
      final parent = _comments[_replyingToIndex!];
      final replies = List<Map<String, dynamic>>.from(parent["replies"] ?? []);
      replies.insert(0, {
        "name": widget.currentUserName,
        "avatarUrl": widget.currentAvatarUrl,
        "userId": currentUser.uid,
        "text": text,
        "liked": false,
        "time": Timestamp.now(),
      });

      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: parent["id"],
        updates: {"replies": replies},
      );

      // Tạo thông báo cho chủ bài viết hoặc chủ bình luận gốc
      final postDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .get();
      final postData = postDoc.data();
      if (postData != null) {
        final senderDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
        final senderData = senderDoc.data();
        if (senderData != null) {
          final senderName = senderData['name'] ?? 'Người dùng';
          final senderAvatarUrl =
              senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

          // Thông báo cho chủ bài viết
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': postData['userId'], // Người nhận thông báo (chủ bài viết)
            'senderId': currentUser.uid,
            'senderName': senderName,
            'senderAvatarUrl': senderAvatarUrl,
            'action': 'đã trả lời bình luận trong bài viết của bạn.',
            'type': 'comment',
            'postId': widget.postId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            'date': 'Hôm nay',
          });

          // Thông báo cho chủ bình luận gốc (nếu không phải là chính người trả lời)
          if (parent['userId'] != currentUser.uid) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId':
                  parent['userId'], // Người nhận thông báo (chủ bình luận gốc)
              'senderId': currentUser.uid,
              'senderName': senderName,
              'senderAvatarUrl': senderAvatarUrl,
              'action': 'đã trả lời bình luận của bạn.',
              'type': 'comment_reply',
              'postId': widget.postId,
              'commentId': parent['id'],
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'date': 'Hôm nay',
            });
          }
        }
      }

      _replyingToIndex = null;
    } else {
      await _commentService.addComment(widget.postId, {
        "name": widget.currentUserName,
        "avatarUrl": widget.currentAvatarUrl,
        "userId": currentUser.uid,
        "text": text.trim(),
        "liked": false,
        "time": Timestamp.now(),
        "isAuthor": false,
        "topComment": false,
        "replies": [],
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'comments': FieldValue.increment(1)});

      // Tạo thông báo cho chủ bài viết
      final postDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .get();
      final postData = postDoc.data();
      if (postData != null) {
        final senderDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
        final senderData = senderDoc.data();
        if (senderData != null) {
          final senderName = senderData['name'] ?? 'Người dùng';
          final senderAvatarUrl =
              senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': postData['userId'], // Người nhận thông báo (chủ bài viết)
            'senderId': currentUser.uid,
            'senderName': senderName,
            'senderAvatarUrl': senderAvatarUrl,
            'action': 'đã bình luận bài viết của bạn.',
            'type': 'comment',
            'postId': widget.postId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            'date': 'Hôm nay',
          });
        }
      }
    }

    _controller.clear();
    _loadComments();
  }

  Future<void> _toggleLike(int index, {int? replyIndex}) async {
    final comment = _comments[index];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (replyIndex != null) {
      final replies = List<Map<String, dynamic>>.from(comment["replies"]);
      final hasLiked = replies[replyIndex]["liked"];
      replies[replyIndex]["liked"] = !hasLiked;
      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: comment["id"],
        updates: {"replies": replies},
      );

      // Tạo hoặc xóa thông báo
      final postDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .get();
      final postData = postDoc.data();
      if (postData != null) {
        final senderDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
        final senderData = senderDoc.data();
        if (senderData != null) {
          final senderName = senderData['name'] ?? 'Người dùng';
          final senderAvatarUrl =
              senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

          if (!hasLiked && comment['userId'] != currentUser.uid) {
            // Tạo thông báo khi thích
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId':
                  comment['userId'], // Người nhận thông báo (chủ bình luận)
              'senderId': currentUser.uid,
              'senderName': senderName,
              'senderAvatarUrl': senderAvatarUrl,
              'action': 'đã thích trả lời của bạn trong bài viết.',
              'type': 'comment_like',
              'postId': widget.postId,
              'commentId': comment['id'],
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'date': 'Hôm nay',
            });
          } else {
            // Xóa thông báo khi bỏ thích
            final notificationSnapshot =
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: comment['userId'])
                    .where('senderId', isEqualTo: currentUser.uid)
                    .where('type', isEqualTo: 'comment_like')
                    .where('postId', isEqualTo: widget.postId)
                    .where('commentId', isEqualTo: comment['id'])
                    .get();
            for (var doc in notificationSnapshot.docs) {
              await doc.reference.delete();
            }
          }
        }
      }
    } else {
      final hasLiked = comment["liked"] ?? false;
      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: comment["id"],
        updates: {"liked": !hasLiked},
      );

      // Tạo hoặc xóa thông báo
      final postDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .get();
      final postData = postDoc.data();
      if (postData != null) {
        final senderDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
        final senderData = senderDoc.data();
        if (senderData != null) {
          final senderName = senderData['name'] ?? 'Người dùng';
          final senderAvatarUrl =
              senderData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';

          if (!hasLiked && comment['userId'] != currentUser.uid) {
            // Tạo thông báo khi thích
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId':
                  comment['userId'], // Người nhận thông báo (chủ bình luận)
              'senderId': currentUser.uid,
              'senderName': senderName,
              'senderAvatarUrl': senderAvatarUrl,
              'action': 'đã thích bình luận của bạn trong bài viết.',
              'type': 'comment_like',
              'postId': widget.postId,
              'commentId': comment['id'],
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'date': 'Hôm nay',
            });
          } else {
            // Xóa thông báo khi bỏ thích
            final notificationSnapshot =
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: comment['userId'])
                    .where('senderId', isEqualTo: currentUser.uid)
                    .where('type', isEqualTo: 'comment_like')
                    .where('postId', isEqualTo: widget.postId)
                    .where('commentId', isEqualTo: comment['id'])
                    .get();
            for (var doc in notificationSnapshot.docs) {
              await doc.reference.delete();
            }
          }
        }
      }
    }

    _loadComments();
  }

  void _editComment(int index) {
    _controller.text = _comments[index]["text"];
    _isEditing = true;
    _editingCommentId = _comments[index]["id"];
    _replyingToIndex = null;
  }

  void _replyToComment(int index) {
    _controller.text = "@${_comments[index]["name"]} ";
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _replyingToIndex = index;
    _isEditing = false;
  }

  Future<void> _deleteComment(int index) async {
    final commentId = _comments[index]["id"];
    await _commentService.deleteComment(widget.postId, commentId);
    _loadComments();
  }

Future<void> _reportComment(int index) async {
    final comment = _comments[index];
    final commentId = comment['id'];
    final userId = comment['userId'];
    const reason = 'Bình luận vi phạm chính sách cộng đồng';

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Tham chiếu Firestore
      final reportRef = FirebaseFirestore.instance.collection('reports').doc();
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Lưu báo cáo và tăng reportScore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('Người dùng không tồn tại');
        }

        final userData = userSnapshot.data()!;
        final reportScore = userData['reportScore'] ?? 0;

        // Lưu báo cáo cho bình luận
        transaction.set(reportRef, {
          'commentId': commentId,
          'reason': reason,
          'timestamp': Timestamp.now(),
          'reportedBy': currentUserId,
          'userId': userId,
          'postId': widget.postId, // Thêm postId để dễ theo dõi
        });

        // Tăng reportScore
        transaction.update(userRef, {
          'reportScore': reportScore + 1,
        });
      });

      // Gửi thông báo cho người bị báo cáo
      await FirebaseFirestore.instance.collection('notifications').add({
        'action': 'Bình luận của bạn đã bị báo cáo do vi phạm chính sách cộng đồng. Vui lòng đọc kỹ quy định và tuân thủ để tránh bị xử lý nặng hơn.',
        'isRead': false,
        'postId': widget.postId,
        'commentId': commentId,
        'senderAvatarUrl': 'assets/images/logos.png',
        'senderName': 'Quản trị viên',
        'timestamp': Timestamp.now(),
        'type': 'warning',
        'userId': userId,
      });

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Báo cáo bình luận đã được gửi'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi báo cáo bình luận: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildReply(int parentIndex, int replyIndex) {
    final reply = _comments[parentIndex]["replies"][replyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 56.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundImage:
              reply["avatarUrl"] != null &&
                      reply["avatarUrl"].toString().isNotEmpty
                  ? NetworkImage(reply["avatarUrl"])
                  : null,
          child:
              (reply["avatarUrl"] == null ||
                      reply["avatarUrl"].toString().isEmpty)
                  ? const Icon(Icons.person, size: 14)
                  : null,
        ),
        title: Text(
          reply["name"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reply["text"]),
            const SizedBox(height: 2),
            Text(
              formatTime(reply["time"]),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            reply["liked"] ? Icons.favorite : Icons.favorite_border,
            color: reply["liked"] ? Colors.red : Colors.grey,
            size: 18,
          ),
          onPressed: () => _toggleLike(parentIndex, replyIndex: replyIndex),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bình luận")),
      body: Column(
        children: [
          ListTile(
            title: Text(
              widget.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.caption),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              reverse: true,
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                final replies = c["replies"] as List;
                final showAll = _showAllReplies[index] ?? false;
                final visibleReplies =
                    showAll ? replies : replies.take(2).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            c["avatarUrl"] != null &&
                                    c["avatarUrl"].toString().isNotEmpty
                                ? NetworkImage(c["avatarUrl"])
                                : null,
                        child:
                            (c["avatarUrl"] == null ||
                                    c["avatarUrl"].toString().isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            c["name"],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (c["isAuthor"])
                            _buildTag("Tác giả", Colors.orange),
                          if (c["topComment"])
                            _buildTag("Top bình luận", Colors.green),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c["text"]),
                          const SizedBox(height: 2),
                          Text(
                            formatTime(c["time"]),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editComment(index);
                              break;
                            case 'delete':
                              _deleteComment(index);
                              break;
                            case 'report':
                              _reportComment(index);
                              break;
                          }
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Xoá'),
                              ),
                              PopupMenuItem(
                                value: 'report',
                                child: Text('Báo cáo'),
                              ),
                            ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              c["liked"]
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: c["liked"] ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleLike(index),
                          ),
                          TextButton(
                            onPressed: () => _replyToComment(index),
                            child: const Text("Phản hồi"),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(
                      visibleReplies.length,
                      (i) => _buildReply(index, i),
                    ),
                    if (!showAll && replies.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: TextButton(
                          onPressed: () {
                            setState(() => _showAllReplies[index] = true);
                          },
                          child: const Text("Xem thêm phản hồi..."),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText:
                          _isEditing
                              ? "Chỉnh sửa bình luận..."
                              : "Viết bình luận...",
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.emoji_emotions),
                        onPressed: () {
                          _controller.text += " 😊";
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _addOrUpdateComment(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
