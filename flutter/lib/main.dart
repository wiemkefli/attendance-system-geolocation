import 'package:attendancesystem/config/app_routes.dart';
import 'package:attendancesystem/screens/admin/admin_main_page.dart';
import 'package:attendancesystem/screens/admin/attendance_report.dart';
import 'package:attendancesystem/screens/admin/group.dart';
import 'package:attendancesystem/screens/admin/lesson.dart';
import 'package:attendancesystem/screens/admin/location.dart';
import 'package:attendancesystem/screens/admin/student.dart';
import 'package:attendancesystem/screens/admin/teacher.dart';
import 'package:attendancesystem/screens/login_page.dart';
import 'package:attendancesystem/screens/signout.dart';
import 'package:attendancesystem/screens/student/attendance_history.dart';
import 'package:attendancesystem/screens/student/profile_page.dart';
import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/student/timetable.dart';
import 'package:attendancesystem/services/background_task.dart' as bg_task;
import 'package:attendancesystem/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(bg_task.callbackDispatcher);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance System',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
