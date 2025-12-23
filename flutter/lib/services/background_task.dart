import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api_client.dart';

const String taskName = "geoBackgroundTask";
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    developer.log("[WORKMANAGER] Task started at ${DateTime.now()}");

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await localNotifications.initialize(initSettings);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      developer.log("[WORKMANAGER] Missing token; skipping.");
      return Future.value(true);
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      developer.log("[WORKMANAGER] Failed to get location: $e");
      return Future.value(true);
    }

    final response = await ApiClient.get(
      'student_timetable.php',
      queryParameters: {'date': today},
      token: token,
    );

    if (response.statusCode != 200) {
      developer.log("[WORKMANAGER] Timetable HTTP ${response.statusCode}");
      return Future.value(true);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      developer.log("[WORKMANAGER] Invalid timetable response body");
      return Future.value(true);
    }

    final lessons = decoded['data'];
    if (lessons is! List) {
      developer.log("[WORKMANAGER] Timetable data is not a list");
      return Future.value(true);
    }

    for (final lesson in lessons) {
      final startTime = (lesson as Map<String, dynamic>)['start_time']?.toString();
      if (startTime == null) continue;

      final timeParts = startTime.split(':');
      if (timeParts.length < 2) continue;

      final lessonStart = DateTime(
        now.year,
        now.month,
        now.day,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
      );

      final minutesUntil = lessonStart.difference(now).inMinutes;
      if (minutesUntil < 0 || minutesUntil > 15) continue;

      final lat = (lesson['latitude'] as num).toDouble();
      final lon = (lesson['longitude'] as num).toDouble();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lon,
      );

      if (distance <= 100) continue;

      final subject = lesson['subject']?.toString() ?? 'Class';
      await localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Reminder',
        '$subject starts in $minutesUntil minutes - you are too far!',
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
    }

    developer.log("[WORKMANAGER] Task complete");
    return Future.value(true);
  });
}

