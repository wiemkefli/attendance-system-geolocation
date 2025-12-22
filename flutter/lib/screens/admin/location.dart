import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendancesystem/screens/admin/admin_main_page.dart';
import 'package:attendancesystem/screens/admin/lesson.dart';
import 'package:attendancesystem/screens/admin/group.dart';
import 'package:attendancesystem/screens/admin/teacher.dart';
import 'package:attendancesystem/screens/admin/student.dart';
import 'package:attendancesystem/screens/admin/attendance_report.dart';
import 'package:attendancesystem/screens/signout.dart';
import 'package:attendancesystem/config/api_config.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  List<Map<String, dynamic>> _locations = [];

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<String?> _getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  Future<void> _loadLocations() async {
    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.get(
      apiUri('location_api.php', queryParameters: {'action': 'GET'}),
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final data = jsonDecode(response.body);
      if (data is List) {
        if (!mounted) return;
        setState(() {
          _locations = List<Map<String, dynamic>>.from(data.map((loc) => {
                'location_id': int.tryParse(loc['location_id'].toString()) ?? 0,
                'name': loc['name'] ?? '',
                'latitude': loc['latitude']?.toString() ?? '',
                'longitude': loc['longitude']?.toString() ?? '',
              }));
        });
      } else {
        _showError('Unexpected data format from server.');
      }
    } catch (e) {
      _showError('Invalid response format: $e');
    }
  }

  Future<void> _addLocation() async {
    final name = _nameController.text.trim();
    final latStr = _latitudeController.text.trim();
    final lonStr = _longitudeController.text.trim();

    if (name.isEmpty || latStr.isEmpty || lonStr.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    double? latitude = double.tryParse(latStr);
    double? longitude = double.tryParse(lonStr);
    if (latitude == null || longitude == null) {
      _showError('Latitude and Longitude must be valid numbers');
      return;
    }

    final token = await _getAdminToken();
    if (token == null) return;

    final response = await http.post(
      apiUri('location_api.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        _nameController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        await _loadLocations();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$name" added')),
        );
      } else {
        _showError(result['message'] ?? 'Failed to add location');
      }
    } catch (e) {
      _showError('Invalid response from server');
    }
  }

  Future<void> _deleteLocation(int locationId) async {
    final token = await _getAdminToken();
    if (token == null) return;
    final response = await http.delete(
      apiUri('location_api.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'location_id': locationId}),
    );

    try {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        await _loadLocations();
      } else {
        _showError(result['message'] ?? 'Failed to delete location');
      }
    } catch (e) {
      _showError('Invalid delete response');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard', const AdminMainPage()),
            _buildDrawerItem(context, Icons.class_, 'Lessons', const LessonsPage()),
            _buildDrawerItem(context, Icons.group, 'Groups', const GroupsPage()),
            _buildDrawerItem(context, Icons.people, 'Teachers', const TeachersPage()),
            _buildDrawerItem(context, Icons.school, 'Students', const StudentsPage()),
            _buildDrawerItem(context, Icons.location_on, 'Locations', const LocationsPage()),
            _buildDrawerItem(context, Icons.assignment, 'Attendance Report', const AttendanceReportPage()),
            _buildDrawerItem(context, Icons.logout, 'Sign out', const SignOutPage()),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _latitudeController,
            decoration: const InputDecoration(
              labelText: 'Latitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _longitudeController,
            decoration: const InputDecoration(
              labelText: 'Longitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addLocation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Add Location'),
          ),
          const SizedBox(height: 20),
          const Text('Available Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _locations.isEmpty
                ? const Center(child: Text('No locations available.'))
                : ListView.builder(
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return Card(
                        elevation: 3,
                        child: ListTile(
                          title: Text(loc['name']),
                          subtitle: Text('Lat: ${loc['latitude']}, Lon: ${loc['longitude']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLocation(loc['location_id']),
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
