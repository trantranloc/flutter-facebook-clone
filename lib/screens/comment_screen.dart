import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/comment_service.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String name;
  final String caption;
  final ScrollController scrollController;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.name,
    required this.caption,
    required this.scrollController,
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
        "name": "Bạn",
        "text": text,
        "liked": false,
        "time": Timestamp.now(),
      });

      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: parent["id"],
        updates: {"replies": replies},
      );
      _replyingToIndex = null;
    } else {
      await _commentService.addComment(widget.postId, {
        "name": "Bạn",
        "text": text.trim(),
        "liked": false,
        "time": Timestamp.now(),
        "isAuthor": false,
        "topComment": false,
        "replies": [],
      });
    }

    _controller.clear();
    _loadComments();
  }

  Future<void> _toggleLike(int index, {int? replyIndex}) async {
    final comment = _comments[index];

    if (replyIndex != null) {
      final replies = List<Map<String, dynamic>>.from(comment["replies"]);
      replies[replyIndex]["liked"] = !replies[replyIndex]["liked"];
      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: comment["id"],
        updates: {"replies": replies},
      );
    } else {
      await _commentService.toggleLikeOrReplies(
        postId: widget.postId,
        commentId: comment["id"],
        updates: {"liked": !(comment["liked"] ?? false)},
      );
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

  void _reportComment() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã báo cáo bình luận.")));
  }

  Widget _buildReply(int parentIndex, int replyIndex) {
    final reply = _comments[parentIndex]["replies"][replyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 56.0),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person, size: 14)),
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
                      leading: const CircleAvatar(child: Icon(Icons.person)),
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
                              _reportComment();
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
