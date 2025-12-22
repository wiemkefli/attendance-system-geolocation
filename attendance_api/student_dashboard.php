<?php
require 'vendor/autoload.php';
require 'db.php'; 
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = getenv('JWT_SECRET') ?: 'your_super_secret_key';

// ✅ Decode token
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

if (!$authHeader) {
    echo json_encode(["success" => false, "message" => "Missing token"]);
    exit();
}

$token = str_replace('Bearer ', '', $authHeader);

try {
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    $student_id = $decoded->data->student_id;
    $group_id = $decoded->data->group_id;
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Invalid token"]);
    exit();
}

// ✅ Parse date
$input = json_decode(file_get_contents("php://input"), true);
$date = $input['date'] ?? date('Y-m-d');
$day = strtolower(trim(date('l', strtotime($date))));

// ✅ Attendance rate
$stmt = $pdo->prepare("SELECT COUNT(*) FROM attendance WHERE student_id = ?");
$stmt->execute([$student_id]);
$total = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM attendance WHERE student_id = ? AND status = 'present'");
$stmt->execute([$student_id]);
$present = $stmt->fetchColumn();

$attendance_rate = ($total > 0) ? round(($present / $total) * 100) . "%" : "0%";

// ✅ Subjects
$stmt = $pdo->prepare("
    SELECT COUNT(DISTINCT s.subject_id)
    FROM lessons l
    JOIN subjects s ON l.subject_id = s.subject_id
    WHERE l.group_id = ?
");
$stmt->execute([$group_id]);
$subjects = $stmt->fetchColumn();

// ✅ Upcoming classes
$stmt = $pdo->prepare("
    SELECT COUNT(*) FROM lessons
    WHERE group_id = ? AND start_date <= ? AND end_date >= ?
");
$stmt->execute([$group_id, $date, $date]);
$upcoming = $stmt->fetchColumn();

// ✅ Today’s classes
$stmt = $pdo->prepare("
    SELECT l.lesson_id, s.name AS subject, l.start_time, l.end_time,
           l.location_id, loc.name AS room
    FROM lessons l
    LEFT JOIN locations loc ON l.location_id = loc.location_id
    LEFT JOIN subjects s ON l.subject_id = s.subject_id
    WHERE l.group_id = ?
      AND LOWER(TRIM(l.day_of_week)) = ?
      AND l.start_date <= ?
      AND l.end_date >= ?
");
$stmt->execute([$group_id, $day, $date, $date]);

$today_classes = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $today_classes[] = [
        'time' => substr($row['start_time'], 0, 5),
        'subject' => $row['subject'],
        'room' => $row['room'] ?? 'Room N/A',
    ];
}

// ✅ Final JSON response
echo json_encode([
    'success' => true,
    'attendance_rate' => $attendance_rate,
    'subjects' => (int)$subjects,
    'upcoming' => (int)$upcoming,
    'today_classes' => $today_classes,
]);
?>
