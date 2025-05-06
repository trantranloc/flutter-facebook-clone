// lib/screens/comment_screen.dart
import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> _comments = [
    {
      "name": "Người A",
      "text": "Bài viết hay quá!",
      "liked": false,
      "replies": List.generate(
        5,
        (i) => {"name": "ReplyUser $i", "text": "Phản hồi $i", "liked": false},
      ),
    },
    {"name": "Người B", "text": "Tôi đồng ý!", "liked": false, "replies": []},
  ];

  final TextEditingController _commentController = TextEditingController();
  int? _replyingToIndex;
  final Map<int, bool> _showAllReplies = {};

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      if (_replyingToIndex != null) {
        _comments[_replyingToIndex!]["replies"].insert(0, {
          "name": "Bạn",
          "text": text,
          "liked": false,
        });
        _replyingToIndex = null;
      } else {
        _comments.insert(0, {
          "name": "Bạn",
          "text": text,
          "liked": false,
          "replies": [],
        });
      }
    });
    _commentController.clear();
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

  void _replyToComment(int index) {
    setState(() {
      _replyingToIndex = index;
    });
    _commentController.text = "@${_comments[index]["name"]} ";
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  Widget _buildReplyTile(int index, int replyIndex) {
    final reply = _comments[index]["replies"][replyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 56.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ListTile(
          leading: const CircleAvatar(
            radius: 14,
            child: Icon(Icons.person, size: 16),
          ),
          title: Text(
            reply["name"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(reply["text"]),
          trailing: IconButton(
            icon: Icon(
              reply["liked"] ? Icons.favorite : Icons.favorite_border,
              color: reply["liked"] ? Colors.red : Colors.grey,
              size: 18,
            ),
            onPressed: () => _toggleLike(index, replyIndex: replyIndex),
          ),
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
                final comment = _comments[index];
                final showAll = _showAllReplies[index] ?? false;
                final replies = comment["replies"];
                final displayReplies =
                    showAll ? replies : replies.take(2).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        comment["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(comment["text"]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              comment["liked"]
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  comment["liked"] ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleLike(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.reply, color: Colors.grey),
                            onPressed: () => _replyToComment(index),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        children: [
                          ...List.generate(
                            displayReplies.length,
                            (i) => _buildReplyTile(index, i),
                          ),
                          if (!showAll && replies.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(left: 56.0),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllReplies[index] = true;
                                  });
                                },
                                child: const Text("Xem thêm phản hồi..."),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Viết bình luận...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _addComment(_commentController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
