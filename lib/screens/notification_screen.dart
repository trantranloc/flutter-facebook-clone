import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  List<Map<String, dynamic>> notifications = [
    {
      'user': 'Jane Smith',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'action': 'đã thích bài viết của bạn.',
      'time': '5 phút trước',
      'type': 'like',
      'isRead': false,
      'date': 'Hôm nay',
    },
    {
      'user': 'John Doe',
      'avatarUrl': 'https://i.pravatar.cc/150?img=12',
      'action': 'đã bình luận về story của bạn.',
      'time': '1 giờ trước',
      'type': 'comment',
      'isRead': false,
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
      'user': 'Anna Lee',
      'avatarUrl': 'https://i.pravatar.cc/150?img=8',
      'action': 'đã xem story của bạn.',
      'time': '2 giờ trước',
      'type': 'story_view',
      'isRead': true,
      'story': Story(
        imageUrl: 'https://picsum.photos/200/301',
        user: 'Your Name',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      'date': 'Hôm nay',
    },
    {
      'user': 'Mike Brown',
      'avatarUrl': 'https://i.pravatar.cc/150?img=15',
      'action': 'đã mời bạn tham gia sự kiện "Hội thảo Flutter 2025".',
      'time': '1 ngày trước',
      'type': 'event',
      'isRead': false,
      'date': 'Hôm qua',
    },
    {
      'user': 'Sarah Wilson',
      'avatarUrl': 'https://i.pravatar.cc/150?img=20',
      'action': 'đã gửi lời mời kết bạn.',
      'time': '1 ngày trước',
      'type': 'friend_request',
      'isRead': false,
      'date': 'Hôm qua',
    },
    {
      'user': 'Tom Clark',
      'avatarUrl': 'https://i.pravatar.cc/150?img=25',
      'action': 'đã chia sẻ bài viết của bạn.',
      'time': '2 ngày trước',
      'type': 'share',
      'isRead': false,
      'date': 'Hôm qua',
    },
    {
      'user': 'Emily Davis',
      'avatarUrl': 'https://i.pravatar.cc/150?img=30',
      'action': 'nhắc bạn về sinh nhật của cô ấy vào ngày mai.',
      'time': '3 ngày trước',
      'type': 'birthday',
      'isRead': true,
      'date': 'Trước đó',
    },
    {
      'user': 'David Miller',
      'avatarUrl': 'https://i.pravatar.cc/150?img=35',
      'action': 'đã gắn thẻ bạn trong một bài viết.',
      'time': '4 ngày trước',
      'type': 'tag',
      'isRead': false,
      'date': 'Trước đó',
    },
    {
      'user': 'Laura Adams',
      'avatarUrl': 'https://i.pravatar.cc/150?img=40',
      'action':
          'đã nhắc bạn về sự kiện "Buổi hòa nhạc ngoài trời" vào ngày mai.',
      'time': '5 ngày trước',
      'type': 'event_reminder',
      'isRead': false,
      'date': 'Trước đó',
    },
    {
      'user': 'Chris Evans',
      'avatarUrl': 'https://i.pravatar.cc/150?img=45',
      'action': 'đã gắn thẻ bạn trong một bình luận.',
      'time': '6 ngày trước',
      'type': 'comment_tag',
      'isRead': true,
      'date': 'Trước đó',
    },
  ];

  String? _selectedFilter = 'Tất cả';

  void _markAsRead(int index) {
    setState(() {
      notifications[index]['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
    );
  }

  void _deleteNotification(int index) {
    final deletedNotification = notifications[index];
    setState(() {
      notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa thông báo từ ${deletedNotification['user']}'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              notifications.insert(index, deletedNotification);
            });
          },
        ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      notifications.insert(0, {
        'user': 'New User',
        'avatarUrl': 'https://i.pravatar.cc/150?img=50',
        'action': 'đã thích bài viết của bạn.',
        'time': 'Vừa xong',
        'type': 'like',
        'isRead': false,
        'date': 'Hôm nay',
      });
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã tải thông báo mới')));
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'Tất cả') return notifications;
    return notifications.where((n) => n['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupNotificationsByDate(
      _filteredNotifications,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _markAllAsRead,
            tooltip: 'Đánh dấu tất cả là đã đọc',
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
      body: RefreshIndicator(
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
                                  key: Key(
                                    '${notification['user']}-${notification['time']}',
                                  ),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed:
                                      (_) => _deleteNotification(
                                        notifications.indexOf(notification),
                                      ),
                                  child: AnimatedOpacity(
                                    opacity: notification['isRead'] ? 0.7 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Card(
                                      elevation: 3,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      color:
                                          notification['isRead']
                                              ? Colors.white
                                              : Colors.blue[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                notification['avatarUrl'],
                                              ),
                                              radius: 22,
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
                                                text: notification['user'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
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
                                          notification['time'],
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
                                            notifications.indexOf(notification),
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
      ),
    );
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
    switch (notification['type']) {
      case 'event':
      case 'event_reminder':
        return ElevatedButton(
          onPressed: () {
            _markAsRead(notifications.indexOf(notification));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventAndBirthdayScreen()),
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
            _markAsRead(notifications.indexOf(notification));
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
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                _markAsRead(notifications.indexOf(notification));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã chấp nhận lời mời từ ${notification['user']}',
                    ),
                  ),
                );
              },
              tooltip: 'Chấp nhận',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _markAsRead(notifications.indexOf(notification));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã từ chối lời mời từ ${notification['user']}',
                    ),
                  ),
                );
              },
              tooltip: 'Từ chối',
            ),
          ],
        );
      case 'birthday':
        return ElevatedButton(
          onPressed: () {
            _markAsRead(notifications.indexOf(notification));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xem hồ sơ của ${notification['user']}')),
        );
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
      final date = notif['date'] as String;
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
