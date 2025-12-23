import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedDay;
  int? _selectedSubjectId;
  int? _selectedTeacherId;
  int? _selectedGroupId;
  int? _selectedLocationId;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _subjects = [];

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchTeachers();
    _fetchGroups();
    _fetchLocations();
    _fetchLessons();
  }

  Future<void> _fetchSubjects() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('subjects_api.php', token: token);
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(raw.map((s) => {
          'subject_id': int.tryParse(s['subject_id']?.toString() ?? '') ?? 0,
          'name': s['name'] ?? ''
        }));
      });
    }
  }

  Future<void> _fetchTeachers() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get(
      'teacher_api.php',
      queryParameters: {'simple': 'true'},
      token: token,
    );
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(raw.map((t) => {
          'teacher_id': int.tryParse(t['teacher_id']?.toString() ?? '') ?? 0,
          'name': t['name'] ?? '',
          'subject_id': int.tryParse(t['subject_id']?.toString() ?? '') ?? 0,
        }));
        // Initialize filtered list empty or full based on subject selection
        _filterTeachers();
      });
    }
  }

  void _filterTeachers() {
    if (_selectedSubjectId == null) {
      _filteredTeachers = [];
    } else {
      _filteredTeachers = _teachers.where((t) => t['subject_id'] == _selectedSubjectId).toList();
    }
    // Reset selected teacher if current selection doesn't match filtered list
    if (!_filteredTeachers.any((t) => t['teacher_id'] == _selectedTeacherId)) {
      _selectedTeacherId = null;
    }
    setState(() {});
  }

  Future<void> _fetchGroups() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('group_api.php', token: token);
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      _groups = List<Map<String, dynamic>>.from(raw.map((g) => {
        'group_id': int.tryParse(g['group_id']?.toString() ?? '') ?? 0,
        'group_name': g['group_name'] ?? ''
      }));
      setState(() {});
    }
  }

  Future<void> _fetchLocations() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('location_api.php', token: token);
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      _locations = List<Map<String, dynamic>>.from(raw.map((loc) => {
        'location_id': int.tryParse(loc['location_id']?.toString() ?? '') ?? 0,
        'name': loc['name'] ?? ''
      }));
      setState(() {});
    }
  }

  Future<void> _fetchLessons() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('lessons_api.php', token: token);
    if (response.statusCode == 200) {
      setState(() {
        _lessons = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }
  }

  Future<void> _addLesson() async {
    if (_selectedSubjectId == null ||
        _selectedTeacherId == null ||
        _selectedGroupId == null ||
        _selectedLocationId == null ||
        _startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null ||
        _selectedDay == null) {
      return;
    }

    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute:00';
    }

    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    final response = await ApiClient.postJson(
      'lessons_api.php',
      token: token,
      body: {
        'subject_id': _selectedSubjectId,
        'teacher_id': _selectedTeacherId,
        'group_id': _selectedGroupId,
        'location_id': _selectedLocationId,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'start_time': formatTimeOfDay(_startTime!),
        'end_time': formatTimeOfDay(_endTime!),
        'day_of_week': _selectedDay,
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      _startDate = _endDate = null;
      _startTime = _endTime = null;
      _selectedDay = null;
      _selectedSubjectId = _selectedTeacherId = _selectedGroupId = _selectedLocationId = null;
      await _fetchLessons();
      setState(() {
        _filteredTeachers = [];
      });
    }
  }

  Future<void> _deleteLesson(int lessonId) async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    final response = await ApiClient.postJson(
      'lessons_api.php',
      token: token,
      body: {'action': 'delete', 'lesson_id': lessonId},
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      await _fetchLessons();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: Text(date == null ? 'Select date' : DateFormat('yyyy-MM-dd').format(date)),
    ),
  );

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: Text(time == null ? 'Select time' : time.format(context)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Lessons')),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminLessons),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Create a Lesson', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Subject Dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            initialValue: _selectedSubjectId,
            items: _subjects.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: s['subject_id'],
                child: Text(s['name']),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSubjectId = val;
                _filterTeachers();  // Filter teachers whenever subject changes
              });
            },
          ),
          const SizedBox(height: 10),

          // Teacher Dropdown filtered by selected subject
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Teacher', border: OutlineInputBorder()),
            initialValue: _selectedTeacherId,
            items: _filteredTeachers.map<DropdownMenuItem<int>>((t) {
              return DropdownMenuItem<int>(
                value: t['teacher_id'],
                child: Text(t['name']),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedTeacherId = val),
          ),
          const SizedBox(height: 10),

          // Group Dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Group', border: OutlineInputBorder()),
            initialValue: _selectedGroupId,
            items: _groups.map<DropdownMenuItem<int>>((g) {
              return DropdownMenuItem<int>(
                value: g['group_id'],
                child: Text(g['group_name']),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedGroupId = val),
          ),
          const SizedBox(height: 10),

          // Location Dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
            initialValue: _selectedLocationId,
            items: _locations.map<DropdownMenuItem<int>>((l) {
              return DropdownMenuItem<int>(
                value: l['location_id'],
                child: Text(l['name']),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedLocationId = val),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _buildDatePicker('Start Date', _startDate, () => _selectDate(context, true))),
              const SizedBox(width: 10),
              Expanded(child: _buildDatePicker('End Date', _endDate, () => _selectDate(context, false))),
            ],
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder()),
            initialValue: _selectedDay,
            items: _daysOfWeek.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) => setState(() => _selectedDay = val),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _buildTimePicker('Start Time', _startTime, () => _selectTime(context, true))),
              const SizedBox(width: 10),
              Expanded(child: _buildTimePicker('End Time', _endTime, () => _selectTime(context, false))),
            ],
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _addLesson,
            child: const Text('Add Lesson'),
          ),
          const SizedBox(height: 20),

          const Text('Available Lessons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Expanded(
            child: _lessons.isEmpty
                ? const Center(child: Text('No lessons available.'))
                : ListView.builder(
                    itemCount: _lessons.length,
                    itemBuilder: (context, index) {
                      final l = _lessons[index];
                      return Card(
                        elevation: 3,
                        child: ListTile(
                          title: Text('${l['class_name']} (${l['subject']})'),
                          subtitle: Text('${l['teacher_name']} | ${l['day_of_week']} | ${l['start_time']} - ${l['end_time']}\nGroup: ${l['group_name']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLesson(l['lesson_id']),
                          ),
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
