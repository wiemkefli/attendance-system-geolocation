import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/services/api_client.dart';
import 'package:attendancesystem/services/auth_storage.dart';
import 'package:attendancesystem/widgets/admin_drawer.dart';

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

  Future<void> _loadLocations() async {
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.get(
      'location_api.php',
      queryParameters: {'action': 'GET'},
      token: token,
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

    final token = await AuthStorage.getAdminToken();
    if (token == null) return;

    final response = await ApiClient.postJson(
      'location_api.php',
      token: token,
      body: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      },
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
    final token = await AuthStorage.getAdminToken();
    if (token == null) return;
    final response = await ApiClient.deleteJson(
      'location_api.php',
      token: token,
      body: {'location_id': locationId},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminLocations),
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
