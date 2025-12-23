import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _subjects = [];
  int? _selectedSubjectId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadSubjects();
  }

  Future<void> _loadTeachers() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('teacher_api.php', token: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(data.map((t) => {
              'teacher_id': int.tryParse(t['teacher_id'].toString()) ?? 0,
              'firstName': t['first_name'],
              'lastName': t['last_name'],
              'email': t['email'],
              'phone': t['phone'],
              'subject_name': t['subject_name'] ?? 'None',
            }));
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load teachers")),
      );
    }
  }

  Future<void> _loadSubjects() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('subjects_api.php', token: token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(data.map((subject) => {
              'subject_id': int.parse(subject['subject_id'].toString()),
              'name': subject['name'],
            }));
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects[0]['subject_id'];
        }
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load subjects")),
      );
    }
  }

  Future<void> _addTeacher() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    final response = await ApiClient.postJson(
      'teacher_api.php',
      token: token,
      body: {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subjectId': _selectedSubjectId,
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      setState(() {
        _selectedSubjectId = _subjects.isNotEmpty ? _subjects[0]['subject_id'] : null;
      });
      await _loadTeachers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher added successfully')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Add failed')),
      );
    }
  }

  Future<void> _deleteTeacher(int teacherId) async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.deleteJson(
      'teacher_api.php',
      token: token,
      body: {'teacher_id': teacherId},
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      await _loadTeachers();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Delete failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminTeachers),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a Teacher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _selectedSubjectId,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              items: _subjects.map((subject) {
                return DropdownMenuItem<int>(
                  value: subject['subject_id'],
                  child: Text(subject['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubjectId = val;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTeacher,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Add Teacher'),
            ),
            const SizedBox(height: 20),
            const Text('List of Teachers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _teachers.isEmpty
                  ? const Center(child: Text('No teachers available.'))
                  : ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        return Card(
                          elevation: 3,
                          child: ListTile(
                            title: Text('${teacher['firstName']} ${teacher['lastName']}'),
                            subtitle: Text(
                              'Email: ${teacher['email']}\nPhone: ${teacher['phone']}\nSubject: ${teacher['subject_name']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTeacher(teacher['teacher_id']),
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
