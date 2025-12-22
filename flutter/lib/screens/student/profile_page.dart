import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/student/timetable.dart';
import 'package:attendancesystem/screens/student/attendance_history.dart';
import 'package:attendancesystem/screens/signout.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, String> studentProfile = {
    'Name': '...',
    'Email': '...',
    'Group': '...',
  };

  final _newPasswordController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/attendance_api/student_profile.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          studentProfile = {
            'Name': '${data['first_name']} ${data['last_name']}',
            'Email': data['email'],
            'Group': data['group_name'] ?? 'N/A',
          };
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters.")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isUpdating = true);

    final response = await http.post(
      Uri.parse('http://10.0.2.2/attendance_api/change_password.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'new_password': newPassword}),
    );

    final result = json.decode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Error')),
    );

    setState(() => _isUpdating = false);
    _newPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
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
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard', const StudentMainPage()),
            _buildDrawerItem(context, Icons.person, 'Profile', const StudentProfilePage()),
            _buildDrawerItem(context, Icons.schedule, 'Timetable', const TimetablePage()),
            _buildDrawerItem(context, Icons.history, 'Attendance History', const AttendanceHistoryPage()),
            _buildDrawerItem(context, Icons.logout, 'Sign out', const SignOutPage()),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...studentProfile.entries.map((e) => _buildProfileCard(e.key, e.value)),
            const Divider(height: 40),
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isUpdating ? null : _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.person_outline, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
