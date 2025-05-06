import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/screens/add_friend_screen.dart';
import 'package:flutter_facebook_clone/screens/home_screen.dart';
import 'package:flutter_facebook_clone/screens/list_friend_screen.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text(
          'Bạn bè',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FriendRequestsScreen()),
                            );
                          },
                          child: const Text(
                            'Lời mời kết bạn',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FriendListScreen()),
                            );
                          },
                          child: const Text(
                            'Bạn bè',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              'Những người bạn có thể biết',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Mỹ Kiều'),
            subtitle: const Text('1 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Nguyễn An'),
            subtitle: const Text('2 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1519345182560-3f2917c472ef?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Lê Minh'),
            subtitle: const Text('3 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Trần Hương'),
            subtitle: const Text('4 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Phạm Ngọc'),
            subtitle: const Text('5 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Hoàng Long'),
            subtitle: const Text('6 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://ix-marketing.imgix.net/focalpoint.png?auto=format,compress&w=1946'),
            ),
            title: const Text('Lý Anh'),
            subtitle: const Text('7 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Đặng Khoa'),
            subtitle: const Text('8 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Vũ Hải'),
            subtitle: const Text('9 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80'),
            ),
            title: const Text('Mai Linh'),
            subtitle: const Text('10 bạn chung'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm bạn bè'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Gõ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}