import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_facebook_clone/client/screens/group/create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  final String groupId;
  const EventsScreen({super.key, required this.groupId});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _groupName;
  String? _groupImageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGroupDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch group details for navigation to CreateEventScreen
  Future<void> _fetchGroupDetails() async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(widget.groupId).get();
      if (groupDoc.exists) {
        setState(() {
          _groupName = groupDoc.data()?['name'] ?? 'Nhóm không tên';
          _groupImageUrl = groupDoc.data()?['coverImageUrl'] ?? '';
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin nhóm';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi lấy thông tin nhóm: $e';
      });
    }
  }

  // Fetch events based on status (upcoming or past)
  Future<List<Map<String, dynamic>>> _fetchEvents(String status) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    Query query = _firestore
        .collection('events')
        .where('groupId', isEqualTo: widget.groupId);

    if (status == 'upcoming') {
      query = query.where('date', isGreaterThanOrEqualTo: now);
    } else {
      query = query.where('date', isLessThan: now);
    }

    try {
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải sự kiện. Vui lòng kiểm tra kết nối hoặc liên hệ hỗ trợ.';
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sự kiện trong nhóm',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _groupName == null || _groupImageUrl == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateEventScreen(
                            groupId: widget.groupId,
                            groupName: _groupName!,
                            groupImageUrl: _groupImageUrl!,
                          ),
                        ),
                      );
                    },
              child: const Text(
                'Tạo',
                style: TextStyle(
                  color: Color(0xFF1877F2),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1877F2),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1877F2),
          tabs: const [
            Tab(text: 'Sắp diễn ra'),
            Tab(text: 'Đã qua'),
          ],
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _fetchGroupDetails();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab "Sắp diễn ra"
                _buildEventsTab('upcoming'),
                // Tab "Đã qua"
                _buildEventsTab('past'),
              ],
            ),
    );
  }

  // Build events tab
  Widget _buildEventsTab(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchEvents(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lỗi khi tải sự kiện. Vui lòng kiểm tra kết nối hoặc liên hệ hỗ trợ.',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Text(
              status == 'upcoming'
                  ? 'Nhóm này không có bất kỳ sự kiện nào sắp diễn ra.'
                  : 'Nhóm này không có bất kỳ sự kiện nào đã qua.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final eventDate = (event['date'] as Timestamp?)?.toDate();
            final formattedDate = eventDate != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(eventDate.toLocal())
                : 'Chưa xác định';
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event['coverImageUrl'] != null && event['coverImageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        event['coverImageUrl'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    leading: event['coverImageUrl'] == null || event['coverImageUrl'].isEmpty
                        ? const Icon(Icons.event, color: Color(0xFF1877F2), size: 40)
                        : null,
                    title: Text(
                      event['title'] ?? 'Sự kiện không tên',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày: $formattedDate',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        if (event['location'] != null && event['location'].isNotEmpty)
                          Text(
                            'Vị trí: ${event['location']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        if (event['description'] != null && event['description'].isNotEmpty)
                          Text(
                            event['description'],
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to event details screen with event['id']
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}