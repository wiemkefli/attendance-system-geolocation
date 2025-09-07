import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String taskName = "geoBackgroundTask";
final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[WORKMANAGER] Task started at ${DateTime.now()}");

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await localNotifications.initialize(initSettings);

    final prefs = await SharedPreferences.getInstance();
    final groupId = prefs.getInt('group_id');
    final token = prefs.getString('token');

    print("[DEBUG] Token: ${token?.substring(0, 10)}...");
    print("[DEBUG] groupId: $groupId");

    if (token == null || groupId == null) {
      print("[DEBUG] Missing token or groupId");
      return Future.value(true);
    }

    final now = DateTime.now();
    final todayWeekday = DateFormat('EEEE').format(now);
    print("[DEBUG] Today is: $todayWeekday");

    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
      print("[DEBUG] Current position: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("[ERROR] Failed to get location: $e");
      return Future.value(true);
    }

    final response = await http.get(
      Uri.parse("http://10.0.2.2/attendance_api/lessons_api.php"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      print("[ERROR] Failed to fetch lessons: ${response.statusCode}");
      return Future.value(true);
    }

    final List<dynamic> lessons = jsonDecode(response.body);
    print("[DEBUG] Lessons fetched: ${lessons.length}");

    for (var lesson in lessons) {
      print("👉 Checking lesson: ${lesson['subject']}");

      if (lesson['group_id'] != groupId) {
        print("❌ Skipped: group_id mismatch (${lesson['group_id']} != $groupId)");
        continue;
      }

      if (lesson['day_of_week'] != todayWeekday) {
        print("❌ Skipped: not scheduled for today (${lesson['day_of_week']} != $todayWeekday)");
        continue;
      }

      final DateTime start = DateTime.parse(lesson['start_date']);
      final DateTime end = DateTime.parse(lesson['end_date']);

      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final startDateOnly = DateTime(start.year, start.month, start.day);
      final endDateOnly = DateTime(end.year, end.month, end.day);

      if (nowDateOnly.isBefore(startDateOnly) || nowDateOnly.isAfter(endDateOnly)) {
        print("❌ Skipped: today not in date range (\$startDateOnly → \$endDateOnly)");
        continue;
      }


      final List<String> timeParts = lesson['start_time'].split(":");
      final lessonStart = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
      final minutesUntil = lessonStart.difference(now).inMinutes;

      if (minutesUntil < 0 || minutesUntil > 15) {
  print("❌ Skipped: class not within next 15 minutes ($minutesUntil minutes)");
  continue;
}


      final double lat = (lesson['latitude'] as num).toDouble();
      final double lon = (lesson['longitude'] as num).toDouble();
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lon);

      print("⏰ $minutesUntil min to class | 📍 $distance m to location");

      if (distance > 100) {
        print("🔔 Triggering notification!");
        await localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'Reminder',
          '${lesson['subject']} starts in $minutesUntil minutes — you are too far!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'class_alerts',
              'Class Alerts',
              channelDescription: 'Notify if student is too far from class',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      } else {
        print("✅ Student is within range (${distance.toStringAsFixed(1)} m), no notification needed.");
      }
    }

    print("[WORKMANAGER] Task complete ✅");
    return Future.value(true);
  });
}
