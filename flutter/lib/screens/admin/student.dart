import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _groups = [];
  int? _selectedGroupId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String _generateRandomPassword(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%&*';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (i) => chars[(rand + i * 17) % chars.length]).join();
  }

  Future<void> _loadInitialData() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('student_api.php', token: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final studentsList = List<Map<String, dynamic>>.from(data['students'].map((s) => {
        'student_id': int.tryParse(s['student_id'].toString()) ?? 0,
        'first_name': s['first_name']?.toString() ?? '',
        'last_name': s['last_name']?.toString() ?? '',
        'email': s['email']?.toString() ?? '',
        'group_id': int.tryParse(s['group_id'].toString()) ?? 0,
      }));

      final groupsList = List<Map<String, dynamic>>.from(data['groups'].map((g) => {
        'group_id': int.tryParse(g['group_id'].toString()) ?? 0,
        'name': g['group_name']?.toString() ?? 'Unknown',
      }));

      if (!mounted) return;
      setState(() {
        _students = studentsList;
        _groups = groupsList;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load students and groups')),
      );
    }
  }

  Future<void> _addStudent() async {
    final generatedPassword = _generateRandomPassword(8);
    final student = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'groupId': _selectedGroupId,
      'password': generatedPassword,
    };

    if (student.values.any((e) => e == null || e == '')) return;

    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    final response = await ApiClient.postJson(
      'student_api.php',
      token: token,
      body: student,
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success']) {
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _selectedGroupId = null;
        await _loadInitialData();
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Student Added"),
            content: Text(
              "The student's account has been created.\n\n"
              "Email: ${student['email']}\n"
              "Password: $generatedPassword\n\n"
              "Please copy and share this with the student. It won't be shown again.",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Add failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid response from server')),
      );
    }
  }

  Future<void> _deleteStudent(int id) async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.deleteJson(
      'student_api.php',
      token: token,
      body: {'student_id': id},
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success']) {
        await _loadInitialData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Delete failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete student')),
      );
    }
  }

  String _getGroupName(int groupId) {
    final group = _groups.firstWhere(
      (g) => g['group_id'] == groupId,
      orElse: () => {'name': 'Unknown'},
    );
    return group['name'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminStudents),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Group', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedGroupId,
                  hint: const Text('Select Group'),
                  isExpanded: true,
                  items: _groups.map((group) {
                    return DropdownMenuItem<int>(
                      value: group['group_id'],
                      child: Text(group['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGroupId = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addStudent,
              child: const Text('Add Student'),
            ),
            const SizedBox(height: 20),
            const Text('List of Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _students.isEmpty
                  ? const Center(child: Text('No students available.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final groupName = _getGroupName(student['group_id']);
                        return Card(
                          elevation: 3,
                          child: ListTile(
                            title: Text('${student['first_name']} ${student['last_name']}'),
                            subtitle: Text(
                              'ID: ${student['student_id']}\nGroup: $groupName\nEmail: ${student['email']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStudent(student['student_id']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


}
