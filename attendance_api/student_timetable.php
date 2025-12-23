<?php
require 'db.php'; // shared PDO + env loading
require_once __DIR__ . '/student_auth.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
    exit();
}

$auth = requireStudentAuth();
$student_id = $auth['student_id'];
$group_id = $auth['group_id'];

$date = $_GET['date'] ?? (new DateTimeImmutable('now'))->format('Y-m-d');
$date_dt = DateTimeImmutable::createFromFormat('Y-m-d', $date);
if (!$date_dt || $date_dt->format('Y-m-d') !== $date) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid date"]);
    exit();
}

$weekday = $date_dt->format('l');

try {
    $stmt = $pdo->prepare("
        SELECT
            l.lesson_id,
            s.name AS subject,
            l.day_of_week,
            l.start_time,
            l.end_time,
            l.start_date,
            l.end_date,
            l.group_id,
            l.location_id,
            loc.latitude,
            loc.longitude,
            loc.name AS location_name,
            CONCAT(t.first_name, ' ', t.last_name) AS teacher_name,
            g.group_name,
            a.status AS attendance_status
        FROM lessons l
        JOIN teachers t ON l.teacher_id = t.teacher_id
        JOIN `groups` g ON l.group_id = g.group_id
        JOIN locations loc ON l.location_id = loc.location_id
        JOIN subjects s ON l.subject_id = s.subject_id
        LEFT JOIN attendance a
          ON a.lesson_id = l.lesson_id
         AND a.student_id = ?
         AND a.attendance_date = ?
        WHERE l.group_id = ?
          AND TRIM(l.day_of_week) = ?
          AND l.start_date <= ?
          AND l.end_date >= ?
        ORDER BY l.start_time ASC
    ");

    $stmt->execute([$student_id, $date, $group_id, $weekday, $date, $date]);

    $lessons = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $row['lesson_id'] = (int)$row['lesson_id'];
        $row['group_id'] = (int)$row['group_id'];
        $row['location_id'] = (int)$row['location_id'];
        $row['latitude'] = (float)$row['latitude'];
        $row['longitude'] = (float)$row['longitude'];
        $lessons[] = $row;
    }

    echo json_encode(["success" => true, "data" => $lessons]);
} catch (PDOException $e) {
    error_log("student_timetable.php DB error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error"]);
}

