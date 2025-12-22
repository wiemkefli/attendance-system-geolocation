import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendancesystem/screens/login_page.dart';
import 'package:attendancesystem/screens/student/student_main_page.dart';
import 'package:attendancesystem/screens/admin/admin_main_page.dart';

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _goBackToMain(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    if (!context.mounted) return;
    if (userType == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminMainPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentMainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => _signOut(context),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => _goBackToMain(context),
              child: const Text('No'),
            ),
          ],
        ),
      );
    });

    return const Scaffold(
      backgroundColor: Colors.transparent,
    );
  }
}
