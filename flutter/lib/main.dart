import 'package:flutter/material.dart';
import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/screens/login_page.dart';
import 'package:attendancesystem/screens/admin/admin_main_page.dart';
import 'package:attendancesystem/screens/admin/attendance_report.dart';
import 'package:attendancesystem/screens/admin/group.dart';
import 'package:attendancesystem/screens/admin/lesson.dart';
import 'package:attendancesystem/screens/admin/location.dart';
import 'package:attendancesystem/screens/admin/student.dart';
import 'package:attendancesystem/screens/admin/teacher.dart';
import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/student/attendance_history.dart';
import 'package:attendancesystem/screens/student/profile_page.dart';
import 'package:attendancesystem/screens/student/timetable.dart';
import 'package:attendancesystem/screens/signout.dart';
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
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.adminHome: (context) => const AdminMainPage(),
        AppRoutes.adminLessons: (context) => const LessonsPage(),
        AppRoutes.adminGroups: (context) => const GroupsPage(),
        AppRoutes.adminTeachers: (context) => const TeachersPage(),
        AppRoutes.adminStudents: (context) => const StudentsPage(),
        AppRoutes.adminLocations: (context) => const LocationsPage(),
        AppRoutes.adminAttendanceReport: (context) => const AttendanceReportPage(),
        AppRoutes.studentHome: (context) => const StudentMainPage(),
        AppRoutes.studentProfile: (context) => const StudentProfilePage(),
        AppRoutes.studentTimetable: (context) => const TimetablePage(),
        AppRoutes.studentAttendanceHistory: (context) => const AttendanceHistoryPage(),
        AppRoutes.signOut: (context) => const SignOutPage(),
      },
    );
  }
}
