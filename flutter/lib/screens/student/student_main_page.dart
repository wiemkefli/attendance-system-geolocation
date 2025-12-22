import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendancesystem/config/api_config.dart';

import 'package:attendancesystem/screens/student/timetable.dart';
import 'package:attendancesystem/screens/student/attendance_history.dart';
import 'package:attendancesystem/screens/signout.dart';
import 'package:attendancesystem/screens/student/profile_page.dart';

const String taskName = "geoBackgroundTask";

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});

  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  String attendanceRate = '...';
  int subjectsCount = 0;
  int upcomingClasses = 0;
  List<Map<String, dynamic>> todayClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  


  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url = apiUri('student_dashboard.php');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'date': today}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        attendanceRate = data['attendance_rate'] ?? '0%';
        subjectsCount = data['subjects'] ?? 0;
        upcomingClasses = data['upcoming'] ?? 0;
        todayClasses =
            List<Map<String, dynamic>>.from(data['today_classes'] ?? []);
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'Student Panel',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard',
                const StudentMainPage()),
            _buildDrawerItem(
                context, Icons.person, 'Profile', const StudentProfilePage()),
            _buildDrawerItem(
                context, Icons.schedule, 'Timetable', const TimetablePage()),
            _buildDrawerItem(context, Icons.history, 'Attendance History',
                const AttendanceHistoryPage()),
            _buildDrawerItem(
                context, Icons.logout, 'Sign out', const SignOutPage()),
          ],
        ),
      ),
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
                              cls['time'],
                              cls['subject'],
                              cls['room'],
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
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
