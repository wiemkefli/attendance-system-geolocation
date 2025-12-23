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
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.primary),
            child: const Text(
              'Student Panel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: colors.primary),
            title: const Text('Dashboard'),
            selected: currentRoute == AppRoutes.studentHome,
            onTap: () => _goTo(context, AppRoutes.studentHome),
          ),
          ListTile(
            leading: Icon(Icons.person, color: colors.primary),
            title: const Text('Profile'),
            selected: currentRoute == AppRoutes.studentProfile,
            onTap: () => _goTo(context, AppRoutes.studentProfile),
          ),
          ListTile(
            leading: Icon(Icons.schedule, color: colors.primary),
            title: const Text('Timetable'),
            selected: currentRoute == AppRoutes.studentTimetable,
            onTap: () => _goTo(context, AppRoutes.studentTimetable),
          ),
          ListTile(
            leading: Icon(Icons.history, color: colors.primary),
            title: const Text('Attendance History'),
            selected: currentRoute == AppRoutes.studentAttendanceHistory,
            onTap: () => _goTo(context, AppRoutes.studentAttendanceHistory),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: colors.primary),
            title: const Text('Sign out'),
            selected: currentRoute == AppRoutes.signOut,
            onTap: () => _goTo(context, AppRoutes.signOut),
          ),
        ],
      ),
    );
  }
}
