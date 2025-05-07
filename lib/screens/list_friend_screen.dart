import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/friend');
          },
        ),
        title: const Text(
          'Bạn bè',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '384 người bạn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sắp xếp',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1877F2)),
                ),
              ],
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('43 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('2 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1519345182560-3f2917c472ef?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('32 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('2 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('45 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('3 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://ix-marketing.imgix.net/focalpoint.png?auto=format,compress&w=1946',
              ),
            ),
            title: const Text('...'),
            subtitle: const Text('15 bạn chung'),
            trailing: const Icon(Icons.more_horiz),
          ),
        ],
      ),
    );
  }
}
