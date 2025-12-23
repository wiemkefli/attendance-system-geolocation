import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendancesystem/config/api_config.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Map<String, dynamic>> _groups = [];
  final Map<int, List<Map<String, dynamic>>> _groupStudents = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<String?> _getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  Future<void> _loadGroups() async {
    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.get(
      apiUri('group_api.php', queryParameters: {'action': 'GET'}),
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final data = jsonDecode(response.body);
      if (data is List) {
        if (!mounted) return;
        setState(() {
          _groups = List<Map<String, dynamic>>.from(data.map((g) => {
                'group_id': int.tryParse(g['group_id'].toString()) ?? 0,
                'group_name': g['group_name'] ?? '',
              }));
          _groupStudents.clear();
        });
      } else {
        _showError('Unexpected data format from server.');
      }
    } catch (e) {
      _showError('Invalid response format: $e');
    }
  }

  Future<void> _addGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;

    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.post(
      apiUri('group_api.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'group_name': name}),
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        _groupNameController.clear();
        await _loadGroups();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$name" added')),
        );
      } else {
        _showError(result['message'] ?? 'Failed to add group');
      }
    } catch (e) {
      _showError('Invalid response from server');
    }
  }

  Future<void> _deleteGroup(int groupId) async {
    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.delete(
      apiUri('group_api.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'group_id': groupId}),
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        await _loadGroups();
      } else {
        _showError(result['message'] ?? 'Failed to delete group');
      }
    } catch (e) {
      _showError('Invalid delete response');
    }
  }

  Future<void> _loadGroupStudents(int groupId) async {
    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.get(
      apiUri('group_api.php', queryParameters: {'action': 'students', 'group_id': groupId}),
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final data = jsonDecode(response.body);
      if (data is List) {
        if (!mounted) return;
        setState(() {
          _groupStudents[groupId] = List<Map<String, dynamic>>.from(data.map((s) => {
                'student_id': int.tryParse(s['student_id'].toString()) ?? 0,
                'first_name': s['first_name'] ?? '',
                'last_name': s['last_name'] ?? '',
                'email': s['email'] ?? '',
              }));
        });
      } else {
        _showError('Unexpected format when loading students');
      }
    } catch (e) {
      _showError('Invalid response while loading students');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminGroups),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Create Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addGroup,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Add Group'),
          ),
          const SizedBox(height: 20),
          const Text('Available Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _groups.isEmpty
                ? const Center(child: Text('No groups available.'))
                : ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final groupId = group['group_id'];
                      final students = _groupStudents[groupId] ?? [];

                      return Card(
                        elevation: 3,
                        child: ExpansionTile(
                          title: Text(group['group_name']),
                          onExpansionChanged: (expanded) {
                            if (expanded && !_groupStudents.containsKey(groupId)) {
                              _loadGroupStudents(groupId);
                            }
                          },
                          children: [
                            if (students.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No students in this group'),
                              ),
                            ...students.map((student) => ListTile(
                                  title: Text('${student['first_name']} ${student['last_name']}'),
                                  subtitle: Text(student['email']),
                                )),
                            TextButton(
                              onPressed: () => _deleteGroup(groupId),
                              child: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }


}
