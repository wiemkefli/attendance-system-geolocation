import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendancesystem/config/api_config.dart';

import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/student/timetable.dart';
import 'package:attendancesystem/screens/student/profile_page.dart';
import 'package:attendancesystem/screens/signout.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<Map<String, dynamic>> _allHistory = [];
  Map<String, List<Map<String, dynamic>>> _groupedHistory = {};
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchHistoryWithToken();
  }

  Future<void> _fetchHistoryWithToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final response = await http.get(
      apiUri('get_attendance_history.php'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        setState(() {
          _allHistory = List<Map<String, dynamic>>.from(json['data']);
        });
        _filterAndGroupByMonth(_selectedMonth);
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterAndGroupByMonth(String yearMonth) {
    final dayOrder = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    final filtered = _allHistory.where((record) {
      final date = record['attendance_date'];
      return date != null && date.startsWith(yearMonth);
    }).toList();

    filtered.sort((a, b) {
      final dayA = dayOrder[a['day_of_week']] ?? 8;
      final dayB = dayOrder[b['day_of_week']] ?? 8;
      return dayA != dayB
          ? dayA.compareTo(dayB)
          : (a['start_time'] ?? '').compareTo(b['start_time'] ?? '');
    });

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var record in filtered) {
      final key = '${record['day_of_week']}, ${record['attendance_date']}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    setState(() {
      _groupedHistory = grouped;
      _selectedMonth = yearMonth;
    });
  }

  List<String> _generateMonthOptions() {
    final months = <String>{};
    for (var record in _allHistory) {
      final dateStr = record['attendance_date'];
      if (dateStr != null) {
        months.add(dateStr.substring(0, 7));
      }
    }

    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final subject = record['subject'];
    final status = record['status'];
    final startTime = record['start_time'];
    final endTime = record['end_time'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$startTime - $endTime'),
        trailing: Text(
          status == 'present' ? '✅ Present' : '❌ Absent',
          style: TextStyle(
            color: status == 'present' ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = _generateMonthOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text('Student Panel', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard', const StudentMainPage()),
            _buildDrawerItem(context, Icons.person, 'Profile', const StudentProfilePage()),
            _buildDrawerItem(context, Icons.schedule, 'Timetable', const TimetablePage()),
            _buildDrawerItem(context, Icons.history, 'Attendance History', const AttendanceHistoryPage()),
            _buildDrawerItem(context, Icons.logout, 'Sign out', const SignOutPage()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMonth,
                    onChanged: (value) {
                      if (value != null) _filterAndGroupByMonth(value);
                    },
                    decoration: const InputDecoration(
                      labelText: "Filter by Month",
                      border: OutlineInputBorder(),
                    ),
                    items: monthOptions.map((month) {
                      final display = DateFormat('MMMM yyyy').format(DateTime.parse('$month-01'));
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(display),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _groupedHistory.isEmpty
                      ? const Center(child: Text("No records found for selected month."))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _groupedHistory.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, top: 16),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                ...entry.value.map(_buildHistoryCard),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
