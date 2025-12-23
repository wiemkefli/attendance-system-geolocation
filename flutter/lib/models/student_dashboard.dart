class TodayClass {
  final String time;
  final String subject;
  final String room;

  const TodayClass({
    required this.time,
    required this.subject,
    required this.room,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) {
    return TodayClass(
      time: json['time']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
    );
  }
}

class StudentDashboard {
  final String attendanceRate;
  final int subjectsCount;
  final int upcomingClasses;
  final List<TodayClass> todayClasses;

  const StudentDashboard({
    required this.attendanceRate,
    required this.subjectsCount,
    required this.upcomingClasses,
    required this.todayClasses,
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    final rawToday = json['today_classes'];
    final classes = rawToday is List
        ? rawToday
            .whereType<Map>()
            .map((e) => TodayClass.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TodayClass>[];

    return StudentDashboard(
      attendanceRate: json['attendance_rate']?.toString() ?? '0%',
      subjectsCount: _parseInt(json['subjects']),
      upcomingClasses: _parseInt(json['upcoming']),
      todayClasses: classes,
    );
  }
}

