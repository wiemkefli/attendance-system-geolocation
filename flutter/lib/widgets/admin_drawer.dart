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
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.primary),
            child: const Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: colors.primary),
            title: const Text('Dashboard'),
            selected: currentRoute == AppRoutes.adminHome,
            onTap: () => _goTo(context, AppRoutes.adminHome),
          ),
          ListTile(
            leading: Icon(Icons.class_, color: colors.primary),
            title: const Text('Lessons'),
            selected: currentRoute == AppRoutes.adminLessons,
            onTap: () => _goTo(context, AppRoutes.adminLessons),
          ),
          ListTile(
            leading: Icon(Icons.group, color: colors.primary),
            title: const Text('Groups'),
            selected: currentRoute == AppRoutes.adminGroups,
            onTap: () => _goTo(context, AppRoutes.adminGroups),
          ),
          ListTile(
            leading: Icon(Icons.people, color: colors.primary),
            title: const Text('Teachers'),
            selected: currentRoute == AppRoutes.adminTeachers,
            onTap: () => _goTo(context, AppRoutes.adminTeachers),
          ),
          ListTile(
            leading: Icon(Icons.school, color: colors.primary),
            title: const Text('Students'),
            selected: currentRoute == AppRoutes.adminStudents,
            onTap: () => _goTo(context, AppRoutes.adminStudents),
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: colors.primary),
            title: const Text('Locations'),
            selected: currentRoute == AppRoutes.adminLocations,
            onTap: () => _goTo(context, AppRoutes.adminLocations),
          ),
          ListTile(
            leading: Icon(Icons.assignment, color: colors.primary),
            title: const Text('Attendance Report'),
            selected: currentRoute == AppRoutes.adminAttendanceReport,
            onTap: () => _goTo(context, AppRoutes.adminAttendanceReport),
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
