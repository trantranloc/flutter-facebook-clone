import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentScreen extends StatefulWidget {
  final String username;
  final String caption;

  const CommentScreen({
    super.key,
    required this.username,
    required this.caption,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  int? _replyingToIndex;
  bool _isEditing = false;
  int? _editingIndex;
  final Map<int, bool> _showAllReplies = {};

  final List<Map<String, dynamic>> _comments = [
    {
      "name": "Người A",
      "text": "Bài viết hay quá!",
      "liked": false,
      "time": DateTime.now().subtract(const Duration(minutes: 2)),
      "replies": List.generate(
        3,
        (i) => {
          "name": "Reply $i",
          "text": "Phản hồi số $i",
          "liked": false,
          "time": DateTime.now().subtract(Duration(minutes: i + 1)),
        },
      ),
      "isAuthor": true,
      "topComment": true,
    },
    {
      "name": "Người B",
      "text": "Tôi đồng ý! 😊",
      "liked": false,
      "time": DateTime.now().subtract(const Duration(hours: 1)),
      "replies": [],
      "isAuthor": false,
      "topComment": false,
    },
  ];

  String formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }

  void _addOrUpdateComment(String text) {
    final now = DateTime.now();
    if (_isEditing && _editingIndex != null) {
      setState(() {
        _comments[_editingIndex!]["text"] = text;
        _comments[_editingIndex!]["time"] = now;
      });
      _isEditing = false;
      _editingIndex = null;
    } else if (_replyingToIndex != null) {
      setState(() {
        _comments[_replyingToIndex!]["replies"].insert(0, {
          "name": "Bạn",
          "text": text,
          "liked": false,
          "time": now,
        });
        _replyingToIndex = null;
      });
    } else {
      setState(() {
        _comments.insert(0, {
          "name": "Bạn",
          "text": text,
          "liked": false,
          "time": now,
          "replies": [],
          "isAuthor": false,
          "topComment": false,
        });
      });
    }
    _controller.clear();
  }

  void _toggleLike(int index, {int? replyIndex}) {
    setState(() {
      if (replyIndex != null) {
        _comments[index]["replies"][replyIndex]["liked"] =
            !_comments[index]["replies"][replyIndex]["liked"];
      } else {
        _comments[index]["liked"] = !_comments[index]["liked"];
      }
    });
  }

  void _editComment(int index) {
    _controller.text = _comments[index]["text"];
    _isEditing = true;
    _editingIndex = index;
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

  void _deleteComment(int index) {
    setState(() {
      _comments.removeAt(index);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bình luận")),
      body: Column(
        children: [
          ListTile(
            title: Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.caption),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
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
                            (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Sửa'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xoá'),
                              ),
                              const PopupMenuItem(
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
}
