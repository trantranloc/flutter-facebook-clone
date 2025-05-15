import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_clone/admin/screens/admin_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Trang Quản Lý',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng quan Quản trị',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Lưới các thẻ tóm tắt
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  int userCount = 0;
                  int blockedUserCount = 0;
                  if (userSnapshot.hasData) {
                    userCount = userSnapshot.data!.docs.length;
                    blockedUserCount =
                        userSnapshot.data!.docs
                            .where(
                              (doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['isBlocked'] ==
                                  true,
                            )
                            .length;
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .where('isReported', isEqualTo: true)
                            .snapshots(),
                    builder: (context, postSnapshot) {
                      int reportedPostCount = 0;
                      if (postSnapshot.hasData) {
                        reportedPostCount = postSnapshot.data!.docs.length;
                      }
                      return AnimatedOpacity(
                        opacity:
                            userSnapshot.hasData && postSnapshot.hasData
                                ? 1.0
                                : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildSummaryCard(
                              context,
                              icon: Icons.people,
                              color: Colors.blue,
                              title: 'Tổng số người dùng',
                              value: userCount.toString(),
                              route: '/admin/user-management',
                              isLoading: !userSnapshot.hasData,
                              error: userSnapshot.hasError,
                            ),
                            _buildSummaryCard(
                              context,
                              icon: Icons.post_add,
                              color: Colors.green,
                              title: 'Bài viết bị báo cáo',
                              value: reportedPostCount.toString(),
                              route: '/admin/post-management',
                              isLoading: !postSnapshot.hasData,
                              error: postSnapshot.hasError,
                            ),
                            _buildSummaryCard(
                              context,
                              icon: Icons.block,
                              color: Colors.red,
                              title: 'Người dùng bị khóa',
                              value: blockedUserCount.toString(),
                              route: '/admin/user-management',
                              isLoading: !userSnapshot.hasData,
                              error: userSnapshot.hasError,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              // Biểu đồ tròn
              const Text(
                'Phân bố trạng thái người dùng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Lỗi tải dữ liệu biểu đồ'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final totalUsers = snapshot.data!.docs.length;
                  final blockedUsers =
                      snapshot.data!.docs
                          .where(
                            (doc) =>
                                (doc.data()
                                    as Map<String, dynamic>)['isBlocked'] ==
                                true,
                          )
                          .length;
                  final activeUsers = totalUsers - blockedUsers;

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: activeUsers.toDouble(),
                                title: 'Hoạt động\n$activeUsers',
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: blockedUsers.toDouble(),
                                title: 'Bị khóa\n$blockedUsers',
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Nút điều hướng
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/admin/overview');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xem Thống kê Chi tiết',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String route,
    required bool isLoading,
    required bool error,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : error
                  ? const Text(
                    'Lỗi',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  )
                  : Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
