import 'package:flutter/material.dart';

import '../config/app_routes.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  void _goTo(BuildContext context, String route) {
    Navigator.pop(context);
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueAccent),
            title: const Text('Dashboard'),
            selected: currentRoute == AppRoutes.adminHome,
            onTap: () => _goTo(context, AppRoutes.adminHome),
          ),
          ListTile(
            leading: const Icon(Icons.class_, color: Colors.blueAccent),
            title: const Text('Lessons'),
            selected: currentRoute == AppRoutes.adminLessons,
            onTap: () => _goTo(context, AppRoutes.adminLessons),
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.blueAccent),
            title: const Text('Groups'),
            selected: currentRoute == AppRoutes.adminGroups,
            onTap: () => _goTo(context, AppRoutes.adminGroups),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blueAccent),
            title: const Text('Teachers'),
            selected: currentRoute == AppRoutes.adminTeachers,
            onTap: () => _goTo(context, AppRoutes.adminTeachers),
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.blueAccent),
            title: const Text('Students'),
            selected: currentRoute == AppRoutes.adminStudents,
            onTap: () => _goTo(context, AppRoutes.adminStudents),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blueAccent),
            title: const Text('Locations'),
            selected: currentRoute == AppRoutes.adminLocations,
            onTap: () => _goTo(context, AppRoutes.adminLocations),
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blueAccent),
            title: const Text('Attendance Report'),
            selected: currentRoute == AppRoutes.adminAttendanceReport,
            onTap: () => _goTo(context, AppRoutes.adminAttendanceReport),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blueAccent),
            title: const Text('Sign out'),
            selected: currentRoute == AppRoutes.signOut,
            onTap: () => _goTo(context, AppRoutes.signOut),
          ),
        ],
      ),
    );
  }
}

