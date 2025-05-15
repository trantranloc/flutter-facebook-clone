import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventAndBirthdayScreen extends StatelessWidget {
  const EventAndBirthdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sự kiện & Sinh nhật'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Upcoming Events Section
          const Text(
            'Sự kiện sắp tới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.calendar,
                color: Color(0xFF1877F2),
              ),
              title: const Text('Hội thảo Flutter Việt Nam 2025'),
              subtitle: const Text('Ngày 15/05/2025, 9:00 AM'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tham gia sự kiện!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tham gia'),
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.calendar,
                color: Color(0xFF1877F2),
              ),
              title: const Text('Buổi hòa nhạc ngoài trời'),
              subtitle: const Text('Ngày 20/05/2025, 7:00 PM'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã quan tâm sự kiện!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Quan tâm'),
              ),
            ),
          ),

          // Birthdays Section
          const SizedBox(height: 20),
          const Text(
            'Sinh nhật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=5',
                ),
              ),
              title: const Text('Jane Smith'),
              subtitle: const Text('Sinh nhật hôm nay'),
              trailing: ElevatedButton(
                onPressed: () {
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
                ),
                child: const Text('Chúc mừng'),
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=12',
                ),
              ),
              title: const Text('John Doe'),
              subtitle: const Text('Sinh nhật ngày mai'),
              trailing: ElevatedButton(
                onPressed: () {
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
                ),
                child: const Text('Chúc mừng'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
