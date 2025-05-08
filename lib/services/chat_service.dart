import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy danh sách bạn bè và tin nhắn gần nhất
  Future<List<Map<String, dynamic>>> getFriendsWithLastMessage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Lấy document của người dùng hiện tại
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      // Lấy danh sách friends
      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);

      List<Map<String, dynamic>> friendsData = [];
      for (String friendId in friends) {
        // Lấy thông tin bạn bè
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (!friendDoc.exists) continue;

        // Tạo chatId duy nhất
        final chatId = [user.uid, friendId]..sort();
        final chatSnapshot = await _firestore
            .collection('messages')
            .doc(chatId.join('_'))
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastMessage = 'Start a conversation';
        bool isActive = friendDoc.data()?['isOnline'] ?? false;
        if (chatSnapshot.docs.isNotEmpty) {
          lastMessage = chatSnapshot.docs.first.data()['message'] ?? lastMessage;
        }

        friendsData.add({
          'uid': friendId,
          'name': friendDoc.data()?['name'] ?? 'Unknown',
          'avatarUrl': friendDoc.data()?['avatarUrl'] ?? 'assets/user.jpg',
          'lastMessage': lastMessage,
          'isActive': isActive,
        });
      }

      return friendsData;
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  // Lấy stream tin nhắn cho một cuộc trò chuyện
  Stream<List<Map<String, dynamic>>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final chatId = [user.uid, otherUserId]..sort();
    return _firestore
        .collection('messages')
        .doc(chatId.join('_'))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'sender': data['senderId'] == user.uid ? 'You' : 'Other',
                'message': data['message'],
                'type': data['type'] ?? 'text',
                'fileUrl': data['fileUrl'],
              };
            }).toList());
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String otherUserId, String message, String type, {String? fileUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatId = [user.uid, otherUserId]..sort();
    await _firestore
        .collection('messages')
        .doc(chatId.join('_'))
        .collection('messages')
        .add({
      'senderId': user.uid,
      'receiverId': otherUserId,
      'message': message,
      'type': type,
      'fileUrl': fileUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }
}