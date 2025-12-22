import 'package:flutter/material.dart';
import 'package:attendancesystem/screens/login_page.dart';
import 'package:attendancesystem/screens/admin/admin_main_page.dart';
import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:workmanager/workmanager.dart';
import 'package:attendancesystem/services/background_task.dart' as bg_task;

import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensurePermissions();

  // ✅ Initialize Workmanager correctly
  Workmanager().initialize(bg_task.callbackDispatcher);


  runApp(const MyApp());
}

Future<void> _ensurePermissions() async {
  final status = await Permission.notification.request();
  debugPrint("🔔 Notification permission granted: $status");

  // Optionally: ask for location permission here too
  final locStatus = await Permission.locationWhenInUse.request();
  debugPrint("📍 Location permission granted: $locStatus");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance System',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/admin': (context) => const AdminMainPage(),
        '/student': (context) => const StudentMainPage(),
      },
    );
  }
}
