import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/student_drawer.dart';

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
    final token = await AuthStorage.getStudentToken();

    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiClient.get(
        'get_attendance_history.php',
        token: token,
      );

      if (response.statusCode == 200) {
        final json = ApiClient.decodeJsonMap(response.body);
        if (json['success'] == true) {
          if (!mounted) return;
          setState(() {
            _allHistory = List<Map<String, dynamic>>.from(json['data']);
          });

          final months = _generateMonthOptions();
          if (months.isNotEmpty) {
            final targetMonth =
                months.contains(_selectedMonth) ? _selectedMonth : months.first;
            _filterAndGroupByMonth(targetMonth);
          } else {
            setState(() {
              _groupedHistory = {};
            });
          }
        }
      }
    } catch (_) {
      // Swallow parsing/network exceptions and show an empty state.
    }

    if (!mounted) return;
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
          status == 'present' ? 'Present' : 'Absent',
          style: TextStyle(
            color: status == 'present' ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = _generateMonthOptions();
    final initialMonth = monthOptions.contains(_selectedMonth)
        ? _selectedMonth
        : (monthOptions.isNotEmpty ? monthOptions.first : null);
    final colors = Theme.of(context).colorScheme;

    if (!_isLoading &&
        monthOptions.isNotEmpty &&
        _selectedMonth != initialMonth &&
        initialMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _filterAndGroupByMonth(initialMonth);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      drawer: const StudentDrawer(currentRoute: AppRoutes.studentAttendanceHistory),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Filter by Month",
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: initialMonth,
                        items: monthOptions.map((month) {
                          final display = DateFormat('MMMM yyyy')
                              .format(DateTime.parse('$month-01'));
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(display),
                          );
                        }).toList(),
                        onChanged: monthOptions.isEmpty
                            ? null
                            : (value) {
                                if (value != null) _filterAndGroupByMonth(value);
                              },
                      ),
                    ),
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
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
