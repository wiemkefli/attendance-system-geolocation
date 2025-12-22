from pathlib import Path
path = Path("lib/screens/login_page.dart")
text = path.read_text(encoding="utf-8")
start = text.index("  Future<void> _login() async {")
end = text.index("\n\n  @override", start)
new_fn = """  Future<void> _login() async {
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

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', userType!);

        if (userType == 'Admin') {
          if (!mounted) return;
          Navigator.pushNamed(context, '/admin');
        } else {
          await prefs.setString('token', data['token']);
          await prefs.setInt('group_id', data['group_id']);

          await Workmanager().cancelAll();
          await Workmanager().registerOneOffTask(
            'geo_reminder_task_once',
            bg_task.taskName,
            initialDelay: const Duration(seconds: 30),
            constraints: Constraints(networkType: NetworkType.connected),
          );

          await Workmanager().registerPeriodicTask(
            'geo_reminder_task_periodic',
            bg_task.taskName,
            frequency: const Duration(minutes: 15),
            initialDelay: const Duration(seconds: 30),
            constraints: Constraints(networkType: NetworkType.connected),
          );

          if (!mounted) return;
          Navigator.pushNamed(context, '/student');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
"""
path.write_text(text[:start] + new_fn + text[end:], encoding="utf-8")
