// FULL UPDATED AttendanceReportPage.dart with PDF export and section view
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  String? selectedGroup;
  String? selectedSubject;
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _reportData = [];
  List<String> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get('group_api.php', token: token);
    if (response.statusCode == 200) {
      setState(() {
        _groups = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }
  }

  Future<void> _fetchSubjectsForGroup(String groupId) async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get(
      'get_subjects_by_group.php',
      queryParameters: {'group_id': groupId},
      token: token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> rawSubjects = json.decode(response.body);
      setState(() {
        _subjects = rawSubjects.map((e) => e.toString()).toList();
        selectedSubject = null;
      });
    }
  }

  Future<void> _fetchAttendanceSummary() async {
    if (selectedGroup == null) return;

    setState(() => _isLoading = true);

    final params = {
      'group_id': selectedGroup!,
      if (selectedSubject != null) 'subject': selectedSubject!,
      if (startDate != null) 'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
      if (endDate != null) 'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
    };

    final token = await AuthStorage.getAdminToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    final response = await ApiClient.get(
      'get_attendance_summary.php',
      queryParameters: params,
      token: token,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success']) {
        final data = List<Map<String, dynamic>>.from(json['data']);
        setState(() {
          _reportData = data;
        });
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _exportToPdf(List<Map<String, dynamic>> reportData) async {
    final pdf = pw.Document();

    for (var session in reportData) {
      final date = session['date'];
      final subject = session['subject'];
      final students = session['session'] as List<dynamic>;

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Date: $date | Subject: $subject', style:  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Student', 'Status'],
                  data: students.map((s) => [s['student'], s['status']]).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Widget _buildSessionTable(Map<String, dynamic> session) {
    final date = session['date'] ?? '';
    final subject = session['subject'] ?? '';
    final List<dynamic> students = session['session'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
  'Date: $date | Subject: $subject',
  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),

        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFE3F2FD)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...students.map((entry) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry['student']),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry['status'].toString().toUpperCase()),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Attendance Report"),
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminAttendanceReport),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedGroup,
              items: _groups.map((group) {
                return DropdownMenuItem(
                  value: group['group_id'].toString(),
                  child: Text(group['group_name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedGroup = value);
                if (value != null) _fetchSubjectsForGroup(value);
              },
              decoration: const InputDecoration(labelText: 'Select Group'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedSubject,
              items: _subjects.map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              )).toList(),
              onChanged: (value) => setState(() => selectedSubject = value),
              decoration: const InputDecoration(labelText: 'Filter by Subject'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: startDate == null ? '' : DateFormat('dd MMM yyyy').format(startDate!),
                    ),
                    decoration: const InputDecoration(labelText: 'Start Date'),
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: endDate == null ? '' : DateFormat('dd MMM yyyy').format(endDate!),
                    ),
                    decoration: const InputDecoration(labelText: 'End Date'),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text("Generate Report"),
                  onPressed: _fetchAttendanceSummary,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export as PDF"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: _reportData.isEmpty ? null : () => _exportToPdf(_reportData),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData.isEmpty
                    ? const Text('No data found.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _reportData.map(_buildSessionTable).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}
