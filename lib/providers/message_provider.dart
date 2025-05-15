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

  // Fetch friends with last message
  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();

    _friendsList = await _chatService.getFriendsWithLastMessage();
    _filteredFriends = _friendsList;
    _isLoading = false;
    notifyListeners();
  }

  // Search friends by name
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

  // Clear search
  void clearSearch() {
    _filteredFriends = _friendsList;
    notifyListeners();
  }
}