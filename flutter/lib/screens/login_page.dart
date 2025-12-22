import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:attendancesystem/services/background_task.dart' as bgTask;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? userType;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final usernameOrEmail = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (userType == null || usernameOrEmail.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      late Uri url;
      late Map<String, String> body;

      if (userType == 'Admin') {
        url = Uri.parse("http://10.0.2.2/attendance_api/admin_login.php");
        body = {
          "username": usernameOrEmail,
          "password": password,
        };
      } else {
        url = Uri.parse("http://10.0.2.2/attendance_api/student_login.php");
        body = {
          "email": usernameOrEmail,
          "password": password,
        };
      }

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', userType!);

        if (userType == 'Admin') {
          Navigator.pushNamed(context, '/admin');
        } else {
          await prefs.setString('token', data['token']);
          await prefs.setInt('group_id', data['group_id']);

          // ✅ Register background notification task AFTER login
          await Workmanager().cancelAll(); // Avoid duplicate
          // 🔁 Schedule fast check
          await Workmanager().registerOneOffTask(
          'geo_reminder_task_once',
           bgTask.taskName,
           initialDelay: const Duration(seconds: 30),
           constraints: Constraints(networkType: NetworkType.connected),
           );

// ⏱️ Schedule every 15 minutes after that
          await Workmanager().registerPeriodicTask(
          'geo_reminder_task_periodic',
           bgTask.taskName,
           frequency: const Duration(minutes: 15),
           initialDelay: const Duration(seconds: 30), // Avoid overlap
           constraints: Constraints(networkType: NetworkType.connected),
           );

          Navigator.pushNamed(context, '/student');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/attt.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Attendance System',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                value: userType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Select User Type'),
                onChanged: (String? newValue) {
                  setState(() {
                    userType = newValue;
                  });
                },
                items: ['Admin', 'Student'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: userType == 'Admin' ? 'Username' : 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon:
                      const Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
