import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<List<Map<String, dynamic>>> getFriendsWithLastMessage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Lỗi: Người dùng chưa đăng nhập');
        return [];
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('Lỗi: Tài khoản người dùng không tồn tại');
        return [];
      }
      if (userDoc.data()?['isBlocked'] == true) {
        print('Lỗi: Tài khoản đã bị khóa');
        return [];
      }

      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
      final pinnedChats = List<String>.from(userDoc.data()?['pinnedChats'] ?? []);
      final groups = List<String>.from(userDoc.data()?['groups'] ?? []);

      List<Map<String, dynamic>> friendsData = [];

      // Handle individual friends
      for (String friendId in friends) {
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (!friendDoc.exists) {
          print('Bạn bè $friendId không tồn tại');
          continue;
        }

        final chatId = [user.uid, friendId]..sort();
        final chatSnapshot = await _firestore
            .collection('messages')
            .doc(chatId.join('_'))
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastMessage = 'Bắt đầu trò chuyện';
        bool isActive = friendDoc.data()?['isOnline'] ?? false;
        if (chatSnapshot.docs.isNotEmpty) {
          lastMessage = chatSnapshot.docs.first.data()['message'] ?? lastMessage;
        }

        friendsData.add({
          'uid': friendId,
          'name': friendDoc.data()?['name'] ?? 'Không xác định',
          'avatarUrl': friendDoc.data()?['avatarUrl'] ?? 'assets/user.jpg',
          'lastMessage': lastMessage,
          'isActive': isActive,
          'isPinned': pinnedChats.contains(friendId),
          'isGroup': false,
        });
      }

      // Handle groups
      for (String groupId in groups) {
        final groupDoc = await _firestore.collection('groups').doc(groupId).get();
        if (!groupDoc.exists) {
          print('Nhóm $groupId không tồn tại');
          continue;
        }

        final chatSnapshot = await _firestore
            .collection('messages')
            .doc(groupId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastMessage = 'Bắt đầu trò chuyện nhóm';
        bool isActive = false;
        if (chatSnapshot.docs.isNotEmpty) {
          lastMessage = chatSnapshot.docs.first.data()['message'] ?? lastMessage;
        }

        friendsData.add({
          'uid': groupId,
          'name': groupDoc.data()?['name'] ?? 'Nhóm không tên',
          'avatarUrl': groupDoc.data()?['avatarUrl'] ?? 'assets/group.jpg',
          'lastMessage': lastMessage,
          'isActive': isActive,
          'isPinned': pinnedChats.contains(groupId),
          'isGroup': true,
        });
      }

      return friendsData;
    } catch (e) {
      print('Lỗi khi lấy danh sách bạn bè: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) {
      print('Lỗi: Người dùng chưa đăng nhập');
      return Stream.value([]);
    }

    final chatId = [user.uid, otherUserId]..sort();
    return _firestore
        .collection('messages')
        .doc(chatId.join('_'))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'sender': data['senderId'] == user.uid ? 'You' : 'Other',
                'message': data['message'],
                'type': data['type'] ?? 'text',
                'fileUrl': data['fileUrl'],
                'timestamp': data['timestamp'],
              };
            }).toList();
          } catch (e) {
            print('Lỗi khi lấy tin nhắn: $e');
            return [];
          }
        });
  }

  Future<void> sendMessage(String otherUserId, String message, String type, {String? fileUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Tài khoản người dùng không tồn tại');
      }
      if (userDoc.data()?['isBlocked'] == true) {
        throw Exception('Tài khoản của bạn đã bị khóa');
      }

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
    } catch (e) {
      print('Lỗi khi gửi tin nhắn: $e');
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }

  Future<void> deleteChat(String chatId, {bool isGroup = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final messagesRef = _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Remove from pinned chats if exists
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userData = await userDoc.get();
      final pinnedChats = List<String>.from(userData.data()?['pinnedChats'] ?? []);
      if (pinnedChats.contains(chatId)) {
        pinnedChats.remove(chatId);
        await userDoc.update({'pinnedChats': pinnedChats});
      }

      if (isGroup) {
        final groups = List<String>.from(userData.data()?['groups'] ?? []);
        if (groups.contains(chatId)) {
          groups.remove(chatId);
          await userDoc.update({'groups': groups});
        }
      }
    } catch (e) {
      print('Lỗi khi xóa cuộc trò chuyện: $e');
      throw Exception('Xóa cuộc trò chuyện thất bại: $e');
    }
  }

  Future<void> togglePinChat(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final userDoc = _firestore.collection('users').doc(user.uid);
      final userData = await userDoc.get();
      final pinnedChats = List<String>.from(userData.data()?['pinnedChats'] ?? []);

      if (pinnedChats.contains(chatId)) {
        pinnedChats.remove(chatId);
      } else {
        pinnedChats.add(chatId);
      }

      await userDoc.update({'pinnedChats': pinnedChats});
    } catch (e) {
      print('Lỗi khi ghim/không ghim cuộc trò chuyện: $e');
      throw Exception('Ghim cuộc trò chuyện thất bại: $e');
    }
  }

  Future<void> editMessage(String otherUserId, String messageId, String newMessage) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final chatId = [user.uid, otherUserId]..sort();
      await _firestore
          .collection('messages')
          .doc(chatId.join('_'))
          .collection('messages')
          .doc(messageId)
          .update({
        'message': newMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi khi chỉnh sửa tin nhắn: $e');
      throw Exception('Chỉnh sửa tin nhắn thất bại: $e');
    }
  }

  Future<void> recallMessage(String otherUserId, String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final chatId = [user.uid, otherUserId]..sort();
      await _firestore
          .collection('messages')
          .doc(chatId.join('_'))
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Lỗi khi thu hồi tin nhắn: $e');
      throw Exception('Thu hồi tin nhắn thất bại: $e');
    }
  }

  Future<void> createGroup(String groupName, List<String> members) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final groupId = _uuid.v4();
      // Create group document
      await _firestore.collection('groups').doc(groupId).set({
        'name': groupName,
        'members': [user.uid, ...members],
        'avatarUrl': 'assets/group.jpg',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });

      // Update users' groups list
      for (String memberId in [user.uid, ...members]) {
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        final groups = List<String>.from(userDoc.data()?['groups'] ?? []);
        if (!groups.contains(groupId)) {
          groups.add(groupId);
          await _firestore.collection('users').doc(memberId).update({
            'groups': groups,
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tạo nhóm: $e');
      throw Exception('Tạo nhóm thất bại: $e');
    }
  }
}