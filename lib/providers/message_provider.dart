import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/services/chat_service.dart';

class MessageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _friendsList = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get friendsList => _filteredFriends;
  bool get isLoading => _isLoading;

  final ChatService _chatService = ChatService();

  MessageProvider() {
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();

    _friendsList = await _chatService.getFriendsWithLastMessage();
    // Sort pinned chats to top
    _friendsList.sort((a, b) {
      final aPinned = a['isPinned'] ?? false;
      final bPinned = b['isPinned'] ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
    _filteredFriends = _friendsList;
    _isLoading = false;
    notifyListeners();
  }

  void searchFriends(String query) {
    if (query.isEmpty) {
      _filteredFriends = _friendsList;
    } else {
      _filteredFriends = _friendsList
          .where((friend) =>
              friend['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _filteredFriends = _friendsList;
    notifyListeners();
  }

  Future<void> deleteChat(String friendId, {bool isGroup = false}) async {
    await _chatService.deleteChat(friendId, isGroup: isGroup);
    await fetchFriends();
  }

  Future<void> togglePinChat(String friendId) async {
    await _chatService.togglePinChat(friendId);
    await fetchFriends();
  }

  Future<void> createGroup(String groupName, List<String> members) async {
    await _chatService.createGroup(groupName, members);
    await fetchFriends();
  }
}
//trạng thái 