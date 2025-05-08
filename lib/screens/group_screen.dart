import 'package:flutter/material.dart';
import 'package:flutter_facebook_clone/screens/home_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
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
          'Nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.group, color: Color(0xFF1877F2)),
                          SizedBox(width: 4),
                          Text('Nhóm của bạn', style: TextStyle(color: Color(0xFF1877F2))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.explore, color: Color(0xFF1877F2)),
                          SizedBox(width: 4),
                          Text('Khám phá', style: TextStyle(color: Color(0xFF1877F2))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.mail, color: Color(0xFF1877F2)),
                          SizedBox(width: 4),
                          Text('Lời mời', style: TextStyle(color: Color(0xFF1877F2))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Sắp xếp',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1877F2)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Truy cập thường xuyên nhất',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tạo nhóm'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Đại học Đồng Á!'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Bóng Đá Phủi Hòa Xuân - Đà Nẵng (Bã...'),
            subtitle: const Text('• 3 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Thành Lý Đỗ Đường Sinh Viên Đà Nẵng'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Cộng đồng Sinh Viên IT'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('HỘI MUA BÁN DIỆN THOẠI CŨ ĐÀ NẴ...'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Hội Bóng Đá Phủi Đà Nẵng [Tìm kẻ - ...'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Hồng Biển Ở Huế'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('PHÒNG TRỌ SINH VIÊN GIÁ RẺ ĐÀ NẴ...'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Hội bóng đá Phủi Đà Nẵng (Tìm kẻ - ...'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.network('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80', width: 50, height: 50),
            title: const Text('Hội bóng đá Phủi Đà Nẵng | Tìm kẻ - ...'),
            subtitle: const Text('• Hơn 25 bài viết mới'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}