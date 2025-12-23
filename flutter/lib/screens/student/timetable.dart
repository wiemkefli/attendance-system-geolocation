import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:attendancesystem/services/api_client.dart';

import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/student/attendance_history.dart';
import 'package:attendancesystem/screens/signout.dart';
import 'package:attendancesystem/screens/student/profile_page.dart';


class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> _lessons = [];
  String? token;
  Position? _currentPosition;
  bool _isLoading = false;

  static const double allowedDistanceMeters = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initWithJWT();
    });
  }

  Future<void> _initWithJWT() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token!)) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired session')),
      );
      return;
    }

    if (!mounted) return;
    await _selectDate(context);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _isLoading = true;
      });

      await _determinePosition();
      await _fetchLessons();
      await _markAbsentIfNeeded();
      await _fetchLessons();

      setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchLessons() async {
    if (token == null) return;

    final selected = DateFormat('yyyy-MM-dd').format(selectedDate);
    final response = await ApiClient.get(
      'student_timetable.php',
      queryParameters: {'date': selected},
      token: token,
    );

    if (response.statusCode != 200) {
      debugPrint('Timetable fetch failed: ${response.statusCode}');
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      debugPrint('Timetable response invalid');
      return;
    }

    final data = decoded['data'];
    if (data is! List) {
      debugPrint('Timetable data is not a list');
      return;
    }

    final lessons = List<Map<String, dynamic>>.from(data);
    for (final lesson in lessons) {
      final lat = double.tryParse(lesson['latitude']?.toString() ?? '');
      final lon = double.tryParse(lesson['longitude']?.toString() ?? '');

      if (_currentPosition != null && lat != null && lon != null) {
        lesson['distance'] = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _lessons = lessons;
    });
  }

  Future<void> _markAttendance(int lessonId) async {
    if (token == null) return;

    final selected = DateFormat('yyyy-MM-dd').format(selectedDate);
    final position = await Geolocator.getCurrentPosition();

    final response = await ApiClient.postJson(
      'mark_attendance.php',
      token: token,
      body: {
        'lesson_id': lessonId,
        'attendance_date': selected,
        'status': 'present',
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    );

    final result = jsonDecode(response.body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Unknown error')));
    await _fetchLessons();
  }

  Future<void> _markAbsentIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final prefs = await SharedPreferences.getInstance();

    for (var lesson in _lessons) {
      final lessonId = int.tryParse(lesson['lesson_id'].toString());
      if (lessonId == null) continue;

      final existingStatus = lesson['attendance_status'];
      if (existingStatus != null) continue;

      final cacheKey = 'absent_${lessonId}_${DateFormat('yyyy-MM-dd').format(selected)}';
      if (prefs.getBool(cacheKey) == true) continue;

      final timeParts = lesson['end_time'].toString().split(':');
      final lessonEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));

      if (selected.isBefore(today) || (selected.isAtSameMomentAs(today) && now.isAfter(lessonEnd))) {
        if (token == null) continue;
        await ApiClient.postJson(
          'mark_attendance.php',
          token: token,
          body: {
            'lesson_id': lessonId,
            'attendance_date': DateFormat('yyyy-MM-dd').format(selectedDate),
            'status': 'absent',
          },
        );
        await prefs.setBool(cacheKey, true);
      }
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateFormat('h:mm a').format(DateTime(0, 1, 1, hour, minute));
    } catch (e) {
      return timeStr;
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Timetable'),
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
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT A DATE TO VIEW TIMETABLE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('dd MMMM yyyy').format(selectedDate),
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, color: Colors.brown),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _lessons.isEmpty
                    ? const Center(child: Text('No lessons available for your group.'))
                    : Column(
                        children: _lessons.map((lesson) {
                          final status = lesson['attendance_status'];
                          final startTime = TimeOfDay.fromDateTime(DateFormat("HH:mm:ss").parse(lesson['start_time']));
                          final endTime = TimeOfDay.fromDateTime(DateFormat("HH:mm:ss").parse(lesson['end_time']));
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                          final nowTime = TimeOfDay.now();

                          bool canMark = selected.isAtSameMomentAs(today) &&
                              (nowTime.hour > startTime.hour ||
                                  (nowTime.hour == startTime.hour && nowTime.minute >= startTime.minute)) &&
                              (nowTime.hour < endTime.hour ||
                                  (nowTime.hour == endTime.hour && nowTime.minute <= endTime.minute));

                          double? distance = lesson['distance'] as double?;
                          bool inRange = distance != null && distance <= allowedDistanceMeters;
                          bool canMarkWithDistance = canMark && inRange;

                          final lessonId = int.parse(lesson['lesson_id'].toString());

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_formatTime(lesson['start_time'])} - ${_formatTime(lesson['end_time'])}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Group: ${lesson['group_name']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.lightGreen,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      lesson['subject'],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Teacher: ${lesson['teacher_name']}'),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Location: ${lesson['location_name'] ?? "Unknown"}',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    inRange ? '📍 In Range' : '⚠️ Too Far',
                                    style: TextStyle(color: inRange ? Colors.green : Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (status == null &&
                                          selected.isAtSameMomentAs(today) &&
                                          canMarkWithDistance) {
                                        _markAttendance(lessonId);
                                      }
                                    },
                                    icon: () {
                                      if (status == 'present') return const Icon(Icons.check);
                                      if (status == 'absent') return const Icon(Icons.close);
                                      if (selected.isBefore(today)) return const Icon(Icons.close);
                                      return const Icon(Icons.info);
                                    }(),
                                    label: () {
                                      if (status == 'present') return const Text('Present');
                                      if (status == 'absent') return const Text('Absent');
                                      if (selected.isBefore(today)) return const Text('Absent');
                                      return Text(canMarkWithDistance ? 'Mark Attendance' : 'Not Available');
                                    }(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: () {
                                        if (status == 'present') return Colors.green;
                                        if (status == 'absent' || selected.isBefore(today)) return Colors.red;
                                        return canMarkWithDistance ? Colors.orangeAccent : Colors.grey;
                                      }(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }
}

