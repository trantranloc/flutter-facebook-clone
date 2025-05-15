import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'notification_settings_screen.dart';
import 'story_view_screen.dart';
import 'event_and_birthday_screen.dart';
import '../models/Story.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedFilter = 'Tất cả';
  Map<String, bool> _notificationSettings = {
    'likes': true,
    'comments': true,
    'stories': true,
    'events': true,
  };
  bool _isLoadingSettings = false;

  // Danh sách thông báo ảo
  List<Map<String, dynamic>> mockNotifications = [
    {
      'id': 'mock1',
      'userId': 'mockUserId',
      'senderId': 'mockSender1',
      'senderName': 'Jane Smith',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=5',
      'action': 'đã thích bài viết của bạn.',
      'time': '5 phút trước',
      'type': 'like',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      'date': 'Hôm nay',
    },
    {
      'id': 'mock2',
      'userId': 'mockUserId',
      'senderId': 'mockSender2',
      'senderName': 'John Doe',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=12',
      'action': 'đã bình luận về story của bạn.',
      'time': '1 giờ trước',
      'type': 'comment',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 1)),
      ),
      'story': Story(
        imageUrl: 'https://picsum.photos/200/300',
        user: 'Your Name',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        caption: 'Amazing day!',
      ),
      'date': 'Hôm nay',
    },
    {
      'id': 'mock3',
      'userId': 'mockUserId',
      'senderId': 'mockSender3',
      'senderName': 'Anna Lee',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=8',
      'action': 'đã xem story của bạn.',
      'time': '2 giờ trước',
      'type': 'story_view',
      'isRead': true,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
      'story': Story(
        imageUrl: 'https://picsum.photos/200/301',
        user: 'Your Name',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      'date': 'Hôm nay',
    },
    {
      'id': 'mock4',
      'userId': 'mockUserId',
      'senderId': 'mockSender4',
      'senderName': 'Mike Brown',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=15',
      'action': 'đã mời bạn tham gia sự kiện "Hội thảo Flutter 2025".',
      'time': '1 ngày trước',
      'type': 'event',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'date': 'Hôm qua',
    },
    {
      'id': 'mock5',
      'userId': 'mockUserId',
      'senderId': 'mockSender5',
      'senderName': 'Sarah Wilson',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=20',
      'action': 'đã gửi lời mời kết bạn.',
      'time': '1 ngày trước',
      'type': 'friend_request',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'date': 'Hôm qua',
    },
    {
      'id': 'mock6',
      'userId': 'mockUserId',
      'senderId': 'mockSender6',
      'senderName': 'Tom Clark',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=25',
      'action': 'đã chia sẻ bài viết của bạn.',
      'time': '2 ngày trước',
      'type': 'share',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      'date': 'Hôm qua',
    },
    {
      'id': 'mock7',
      'userId': 'mockUserId',
      'senderId': 'mockSender7',
      'senderName': 'Emily Davis',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=30',
      'action': 'nhắc bạn về sinh nhật của cô ấy vào ngày mai.',
      'time': '3 ngày trước',
      'type': 'birthday',
      'isRead': true,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 3)),
      ),
      'date': 'Trước đó',
    },
    {
      'id': 'mock8',
      'userId': 'mockUserId',
      'senderId': 'mockSender8',
      'senderName': 'David Miller',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=35',
      'action': 'đã gắn thẻ bạn trong một bài viết.',
      'time': '4 ngày trước',
      'type': 'tag',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 4)),
      ),
      'date': 'Trước đó',
    },
    {
      'id': 'mock9',
      'userId': 'mockUserId',
      'senderId': 'mockSender9',
      'senderName': 'Laura Adams',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=40',
      'action':
          'đã nhắc bạn về sự kiện "Buổi hòa nhạc ngoài trời" vào ngày mai.',
      'time': '5 ngày trước',
      'type': 'event_reminder',
      'isRead': false,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 5)),
      ),
      'date': 'Trước đó',
    },
    {
      'id': 'mock10',
      'userId': 'mockUserId',
      'senderId': 'mockSender10',
      'senderName': 'Chris Evans',
      'senderAvatarUrl': 'https://i.pravatar.cc/150?img=45',
      'action': 'đã gắn thẻ bạn trong một bình luận.',
      'time': '6 ngày trước',
      'type': 'comment_tag',
      'isRead': true,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 6)),
      ),
      'date': 'Trước đó',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // Load notification settings from Firestore
  Future<void> _loadNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Tạo tài liệu mới nếu không tồn tại
        await _firestore.collection('users').doc(user.uid).set({
          'notificationSettings': {
            'likes': true,
            'comments': true,
            'stories': true,
            'events': true,
          },
        }, SetOptions(merge: true));
      } else {
        final data = doc.data();
        if (data != null && data['notificationSettings'] != null) {
          setState(() {
            _notificationSettings = {
              'likes': data['notificationSettings']['likes'] ?? true,
              'comments': data['notificationSettings']['comments'] ?? true,
              'stories': data['notificationSettings']['stories'] ?? true,
              'events': data['notificationSettings']['events'] ?? true,
            };
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải cài đặt thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId, bool isMock) async {
    if (isMock) {
      setState(() {
        final index = mockNotifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          mockNotifications[index]['isRead'] = true;
        }
      });
    } else {
      try {
        await _firestore.collection('notifications').doc(notificationId).update(
          {'isRead': true},
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi đánh dấu đã đọc: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> notifications) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final notificationSnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in notificationSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      setState(() {
        for (var notification in mockNotifications) {
          notification['isRead'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đánh dấu tất cả đã đọc: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId, bool isMock) async {
    if (isMock) {
      setState(() {
        final index = mockNotifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          mockNotifications.removeAt(index);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo ảo')));
      }
    } else {
      try {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa thông báo: $e')));
        }
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã làm mới thông báo')));
    }
  }

  Future<void> _handleFriendRequest(String friendUid, bool accept) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      if (accept) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'friends': FieldValue.arrayUnion([friendUid]),
          'pendingRequests': FieldValue.arrayRemove([friendUid]),
        });
        await _firestore.collection('users').doc(friendUid).update({
          'friends': FieldValue.arrayUnion([currentUser.uid]),
          'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận lời mời')));
        }
      } else {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'pendingRequests': FieldValue.arrayRemove([friendUid]),
        });
        await _firestore.collection('users').doc(friendUid).update({
          'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xử lý lời mời: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _filterNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    final filteredBySettings =
        notifications.where((n) {
          if (n['type'] == 'like' && !_notificationSettings['likes']!)
            return false;
          if ((n['type'] == 'comment' || n['type'] == 'comment_tag') &&
              !_notificationSettings['comments']!)
            return false;
          if (n['type'] == 'story_view' && !_notificationSettings['stories']!) {
            return false;
          }
          if ((n['type'] == 'event' ||
                  n['type'] == 'event_reminder' ||
                  n['type'] == 'birthday') &&
              !_notificationSettings['events']!)
            return false;
          return true;
        }).toList();

    if (_selectedFilter == 'Tất cả') return filteredBySettings;
    return filteredBySettings
        .where((n) => n['type'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem thông báo')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        elevation: 0,
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () => _markAllAsRead(mockNotifications),
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => context.push('/friend-requests'),
            tooltip: 'Xem lời mời kết bạn',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
            tooltip: 'Cài đặt thông báo',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('notifications')
                .where('userId', isEqualTo: currentUser.uid)
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingSettings) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi khi tải thông báo: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> notifications = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            notifications =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'userId': data['userId'] ?? '',
                    'senderId': data['senderId'] ?? '',
                    'senderName': data['senderName'] ?? 'Người dùng',
                    'senderAvatarUrl':
                        data['senderAvatarUrl'] ??
                        'https://i.pravatar.cc/150?img=1',
                    'action': data['action'] ?? 'đã thực hiện một hành động.',
                    'type': data['type'] ?? 'unknown',
                    'isRead': data['isRead'] ?? false,
                    'timestamp': data['timestamp'],
                    'date': data['date'] ?? 'Hôm nay',
                    'isMock': false,
                  };
                }).toList();
          } else {
            notifications =
                mockNotifications.map((notification) {
                  return {...notification, 'isMock': true};
                }).toList();
          }

          final filteredNotifications = _filterNotifications(notifications);
          final groupedNotifications = _groupNotificationsByDate(
            filteredNotifications,
          );

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', null),
                        _buildFilterChip('Thích', 'like'),
                        _buildFilterChip('Bình luận', 'comment'),
                        _buildFilterChip('Story', 'story_view'),
                        _buildFilterChip('Sự kiện', 'event'),
                        _buildFilterChip('Kết bạn', 'friend_request'),
                        _buildFilterChip('Sinh nhật', 'birthday'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child:
                      groupedNotifications.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có thông báo nào',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: groupedNotifications.length,
                            itemBuilder: (context, index) {
                              final group = groupedNotifications[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      group['date'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  ...group['notifications'].asMap().entries.map<
                                    Widget
                                  >((entry) {
                                    final idx = entry.key;
                                    final notification = entry.value;
                                    return Dismissible(
                                      key: Key('${notification['id']}'),
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 16.0,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed:
                                          (_) => _deleteNotification(
                                            notification['id'],
                                            notification['isMock'],
                                          ),
                                      child: AnimatedOpacity(
                                        opacity:
                                            notification['isRead'] ? 0.7 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Card(
                                          elevation: 3,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          color:
                                              notification['isRead']
                                                  ? Colors.white
                                                  : Colors.blue[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color:
                                                  notification['isRead']
                                                      ? Colors.transparent
                                                      : Colors.blue[100]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: ListTile(
                                            leading: Stack(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    if (notification['type'] ==
                                                        'friend_request') {
                                                      context.push(
                                                        '/other-profile/${notification['senderId']}',
                                                      );
                                                    }
                                                  },
                                                  child: CircleAvatar(
                                                    backgroundImage: NetworkImage(
                                                      notification['senderAvatarUrl'],
                                                    ),
                                                    radius: 22,
                                                    onBackgroundImageError:
                                                        (_, __) => const Icon(
                                                          Icons.person,
                                                        ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: _buildNotificationIcon(
                                                    notification['type'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            title: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        notification['senderName'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' ${notification['action']}',
                                                    style: TextStyle(
                                                      color:
                                                          notification['isRead']
                                                              ? Colors.grey
                                                              : Colors.black87,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            subtitle: Text(
                                              _formatTimestamp(
                                                notification['timestamp'],
                                              ),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            trailing: _buildNotificationAction(
                                              context,
                                              notification,
                                              idx,
                                            ),
                                            onTap: () {
                                              _markAsRead(
                                                notification['id'],
                                                notification['isMock'],
                                              );
                                              _handleNotificationTap(
                                                context,
                                                notification,
                                              );
                                            },
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Vừa xong';
    try {
      final dateTime = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Vừa xong';
      if (difference.inMinutes < 60)
        return '${difference.inMinutes} phút trước';
      if (difference.inHours < 24) return '${difference.inHours} giờ trước';
      if (difference.inDays < 7) return '${difference.inDays} ngày trước';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Vừa xong';
    }
  }

  Widget _buildFilterChip(String label, String? type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == (type ?? 'Tất cả'),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? (type ?? 'Tất cả') : 'Tất cả';
          });
        },
        selectedColor: const Color(0xFF1877F2),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color:
              _selectedFilter == (type ?? 'Tất cả')
                  ? Colors.white
                  : Colors.black87,
        ),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.red,
          child: const Icon(
            FontAwesomeIcons.heart,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'comment':
      case 'comment_tag':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.blue,
          child: const Icon(
            FontAwesomeIcons.comment,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'story_view':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.green,
          child: const Icon(
            FontAwesomeIcons.eye,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'event':
      case 'event_reminder':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.orange,
          child: const Icon(
            FontAwesomeIcons.calendar,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'friend_request':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.purple,
          child: const Icon(
            FontAwesomeIcons.userPlus,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'share':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.teal,
          child: const Icon(
            FontAwesomeIcons.share,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'birthday':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.pink,
          child: const Icon(
            FontAwesomeIcons.cakeCandles,
            size: 12,
            color: Colors.white,
          ),
        );
      case 'tag':
        return CircleAvatar(
          radius: 10,
          backgroundColor: Colors.indigo,
          child: const Icon(
            FontAwesomeIcons.tag,
            size: 12,
            color: Colors.white,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget? _buildNotificationAction(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
  ) {
    if (notification['isMock']) {
      switch (notification['type']) {
        case 'event':
        case 'event_reminder':
          return ElevatedButton(
            onPressed: () {
              _markAsRead(notification['id'], true);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventAndBirthdayScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: Text(
              notification['type'] == 'event' ? 'Tham gia' : 'Xem sự kiện',
            ),
          );
        case 'comment':
        case 'comment_tag':
          return IconButton(
            icon: const Icon(Icons.reply, color: Color(0xFF1877F2)),
            onPressed: () {
              _markAsRead(notification['id'], true);
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Trả lời bình luận'),
                      content: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Viết trả lời...',
                        ),
                        onSubmitted: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Trả lời: $value')),
                          );
                          Navigator.pop(context);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ],
                    ),
              );
            },
            tooltip: 'Trả lời',
          );
        case 'friend_request':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _markAsRead(notification['id'], true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã chấp nhận lời mời từ ${notification['senderName']} (ảo)',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Chấp nhận'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _markAsRead(notification['id'], true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã từ chối lời mời từ ${notification['senderName']} (ảo)',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Từ chối'),
              ),
            ],
          );
        case 'birthday':
          return ElevatedButton(
            onPressed: () {
              _markAsRead(notification['id'], true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi lời chúc mừng!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: const Text('Chúc mừng'),
          );
        default:
          return null;
      }
    } else {
      switch (notification['type']) {
        case 'event':
        case 'event_reminder':
          return ElevatedButton(
            onPressed: () {
              _markAsRead(notification['id'], false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventAndBirthdayScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: Text(
              notification['type'] == 'event' ? 'Tham gia' : 'Xem sự kiện',
            ),
          );
        case 'comment':
        case 'comment_tag':
          return IconButton(
            icon: const Icon(Icons.reply, color: Color(0xFF1877F2)),
            onPressed: () {
              _markAsRead(notification['id'], false);
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Trả lời bình luận'),
                      content: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Viết trả lời...',
                        ),
                        onSubmitted: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Trả lời: $value')),
                          );
                          Navigator.pop(context);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ],
                    ),
              );
            },
            tooltip: 'Trả lời',
          );
        case 'friend_request':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _markAsRead(notification['id'], false);
                  await _handleFriendRequest(notification['senderId'], true);
                  await _deleteNotification(notification['id'], false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Chấp nhận'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  await _markAsRead(notification['id'], false);
                  await _handleFriendRequest(notification['senderId'], false);
                  await _deleteNotification(notification['id'], false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Từ chối'),
              ),
            ],
          );
        case 'birthday':
          return ElevatedButton(
            onPressed: () {
              _markAsRead(notification['id'], false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi lời chúc mừng!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: const Text('Chúc mừng'),
          );
        default:
          return null;
      }
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    switch (notification['type']) {
      case 'comment':
      case 'story_view':
      case 'comment_tag':
        if (notification['story'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => StoryViewScreen(
                    stories: [notification['story']],
                    initialIndex: 0,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xem: ${notification['action']}')),
          );
        }
        break;
      case 'event':
      case 'event_reminder':
      case 'birthday':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventAndBirthdayScreen()),
        );
        break;
      case 'friend_request':
        context.push('/other-profile/${notification['senderId']}');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xem: ${notification['action']}')),
        );
    }
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<Map<String, dynamic>> notifs,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var notif in notifs) {
      final date = notif['date'] as String? ?? 'Hôm nay';
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notif);
    }
    return grouped.entries
        .map((entry) => {'date': entry.key, 'notifications': entry.value})
        .toList()
      ..sort((a, b) {
        const order = {'Hôm nay': 0, 'Hôm qua': 1, 'Trước đó': 2};
        return order[a['date']]!.compareTo(order[b['date']]!);
      });
  }
}
