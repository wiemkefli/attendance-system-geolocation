import 'package:flutter/material.dart';

import '../config/app_routes.dart';

class StudentDrawer extends StatelessWidget {
  final String currentRoute;

  const StudentDrawer({super.key, required this.currentRoute});

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
              'Student Panel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueAccent),
            title: const Text('Dashboard'),
            selected: currentRoute == AppRoutes.studentHome,
            onTap: () => _goTo(context, AppRoutes.studentHome),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blueAccent),
            title: const Text('Profile'),
            selected: currentRoute == AppRoutes.studentProfile,
            onTap: () => _goTo(context, AppRoutes.studentProfile),
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.blueAccent),
            title: const Text('Timetable'),
            selected: currentRoute == AppRoutes.studentTimetable,
            onTap: () => _goTo(context, AppRoutes.studentTimetable),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blueAccent),
            title: const Text('Attendance History'),
            selected: currentRoute == AppRoutes.studentAttendanceHistory,
            onTap: () => _goTo(context, AppRoutes.studentAttendanceHistory),
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

