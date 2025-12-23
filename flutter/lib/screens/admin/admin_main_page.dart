import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int students = 0;
  int teachers = 0;
  int lessons = 0;
  List<Map<String, dynamic>> teacherList = [];

  // Hardcoded subject map: subject_id -> subject name
  final Map<int, String> subjectNames = {
    1: "Math",
    2: "Physics",
    3: "English",
    // Add more subject mappings here
  };

  @override
  void initState() {
    super.initState();
    _fetchAdminDashboardData();
    _fetchTeachers();
  }

  Future<void> _fetchAdminDashboardData() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    try {
      final response = await ApiClient.postJson('admin_dashboard.php', token: token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            students = data['students'] ?? 0;
            teachers = data['teachers'] ?? 0;
            lessons = data['lessons'] ?? 0;
          });
        } else {
          debugPrint("Admin dashboard error: ${data['message']}");
        }
      } else {
        debugPrint("HTTP error fetching admin dashboard: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching admin dashboard: $e");
    }
  }

  Future<void> _fetchTeachers() async {
    try {
      final token = await AuthStorage.getAdminToken();
      if (token == null) return;
      final response = await ApiClient.get(
        'teacher_api.php',
        queryParameters: {'simple': 'true'},
        token: token,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            teacherList = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        debugPrint("HTTP error fetching teachers: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminHome),
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
                _buildSummaryCard('$students', 'Students', Icons.person),
                _buildSummaryCard('$teachers', 'Teachers', Icons.school),
                _buildSummaryCard('$lessons', 'Lessons', Icons.class_),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Teachers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...teacherList.map((t) {
              final subjectId = (t['subject_id'] is int)
                  ? t['subject_id']
                  : int.tryParse(t['subject_id'].toString()) ?? 0;
              final subjectName = subjectNames[subjectId] ?? 'Unknown Subject';
              return _buildTeacherList(t['name'] ?? '', subjectName);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String value, String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: colors.primary),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherList(String name, String subject) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primary,
        child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white)),
      ),
      title: Text(name),
      subtitle: Text(subject),
    );
  }
}
