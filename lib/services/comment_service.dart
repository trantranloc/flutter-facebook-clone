import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Thêm một bình luận mới vào postId
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment);
  }

  /// Tải danh sách bình luận của postId
  Future<List<Map<String, dynamic>>> loadComments(String postId) async {
    final snapshot =
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .orderBy('time', descending: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'replies': List<Map<String, dynamic>>.from(data['replies'] ?? []),
      };
    }).toList();
  }

  /// Cập nhật nội dung bình luận
  Future<void> updateComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'text': newText, 'time': Timestamp.now()});
  }

  /// Xoá bình luận
  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  /// Cập nhật trạng thái "thích" hoặc danh sách replies
  Future<void> toggleLikeOrReplies({
    required String postId,
    required String commentId,
    required Map<String, dynamic> updates,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update(updates);
  }
}
