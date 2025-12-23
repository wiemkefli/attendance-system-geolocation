import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/models/student_dashboard.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/student_drawer.dart';

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});

  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  String attendanceRate = '...';
  int subjectsCount = 0;
  int upcomingClasses = 0;
  List<TodayClass> todayClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  


  Future<void> _fetchDashboardData() async {
    final token = await AuthStorage.getStudentToken();
    if (token == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final response = await ApiClient.postJson(
      'student_dashboard.php',
      token: token,
      body: {'date': today},
    );

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJsonMap(response.body);
      final dashboard = StudentDashboard.fromJson(data);
      setState(() {
        attendanceRate = dashboard.attendanceRate;
        subjectsCount = dashboard.subjectsCount;
        upcomingClasses = dashboard.upcomingClasses;
        todayClasses = dashboard.todayClasses;
      });
    } else {
      debugPrint('Dashboard fetch failed: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: const StudentDrawer(currentRoute: AppRoutes.studentHome),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSummaryCard(
                    attendanceRate, 'Attendance', Icons.check_circle_outline),
                _buildSummaryCard(subjectsCount.toString(), 'Subjects',
                    Icons.book),
                _buildSummaryCard(upcomingClasses.toString(),
                    'Upcoming Classes', Icons.schedule),
              ],
            ),
            const SizedBox(height: 20),
          
            const SizedBox(height: 30),
            const Text(
              "Today's Classes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            todayClasses.isEmpty
                ? const Text('No classes today.')
                : Column(
                    children: todayClasses
                        .map((cls) => _buildClassSchedule(
                              cls.time,
                              cls.subject,
                              cls.room,
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String value, String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSchedule(String time, String subject, String room) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.blueAccent),
        title: Text(subject),
        subtitle: Text('Time: $time\nRoom: $room'),
      ),
    );
  }
}
