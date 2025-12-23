<?php
require 'vendor/autoload.php';
require 'db.php'; // use shared PDO
require_once __DIR__ . '/jwt_secret.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = getJwtSecretKey();

// Get and decode JWT
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

if (!$authHeader) {
    echo json_encode(["success" => false, "message" => "Missing token"]);
    exit();
}

$token = str_replace('Bearer ', '', $authHeader);

try {
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    $student_id = (int)$decoded->data->student_id;
    $group_id = (int)$decoded->data->group_id;
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Invalid token"]);
    exit();
}

// Read POST data
$data = json_decode(file_get_contents("php://input"), true);
$lesson_id = intval($data["lesson_id"] ?? 0);
$attendance_date = $data["attendance_date"] ?? '';
$status = $data["status"] ?? '';
$student_lat = isset($data["latitude"]) ? floatval($data["latitude"]) : null;
$student_lon = isset($data["longitude"]) ? floatval($data["longitude"]) : null;

if ($lesson_id <= 0) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid lesson_id"]);
    exit();
}

$attendance_dt = DateTimeImmutable::createFromFormat('Y-m-d', $attendance_date);
if (!$attendance_dt || $attendance_dt->format('Y-m-d') !== $attendance_date) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid attendance_date"]);
    exit();
}

if ($status !== 'present' && $status !== 'absent') {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid status"]);
    exit();
}

// Prevent data loss: never allow a previously-marked "present" to be overwritten to "absent".
$existing_stmt = $pdo->prepare("SELECT status FROM attendance WHERE student_id = ? AND lesson_id = ? AND attendance_date = ?");
$existing_stmt->execute([$student_id, $lesson_id, $attendance_date]);
$existing_status = $existing_stmt->fetchColumn();
if ($existing_status === 'present' && $status !== 'present') {
    echo json_encode(["success" => true, "message" => "Attendance already marked present"]);
    exit();
}

// Load lesson details (including location) and validate this student is allowed to mark it.
$loc_sql = "
    SELECT
        l.group_id,
        l.day_of_week,
        l.start_time,
        l.end_time,
        l.start_date,
        l.end_date,
        loc.latitude,
        loc.longitude
    FROM lessons l
    JOIN locations loc ON l.location_id = loc.location_id
    WHERE l.lesson_id = ?
";
$loc_stmt = $pdo->prepare($loc_sql);
$loc_stmt->execute([$lesson_id]);
$lesson_loc = $loc_stmt->fetch(PDO::FETCH_ASSOC);

if (!$lesson_loc) {
    echo json_encode(["success" => false, "message" => "Lesson not found"]);
    exit();
}

$lesson_group_id = (int)$lesson_loc['group_id'];
if ($lesson_group_id !== $group_id) {
    http_response_code(403);
    echo json_encode(["success" => false, "message" => "Lesson does not belong to your group"]);
    exit();
}

$lesson_start = DateTimeImmutable::createFromFormat('Y-m-d', $lesson_loc['start_date']);
$lesson_end = DateTimeImmutable::createFromFormat('Y-m-d', $lesson_loc['end_date']);
if (!$lesson_start || !$lesson_end) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Invalid lesson date configuration"]);
    exit();
}

if ($attendance_dt < $lesson_start || $attendance_dt > $lesson_end) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Date is outside the lesson schedule"]);
    exit();
}

$expected_weekday = $lesson_loc['day_of_week'];
if ($attendance_dt->format('l') !== $expected_weekday) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Date does not match the lesson weekday"]);
    exit();
}

$target_lat = floatval($lesson_loc["latitude"]);
$target_lon = floatval($lesson_loc["longitude"]);

function haversineDistance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371000;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon / 2) * sin($dLon / 2);
    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    return $earthRadius * $c;
}

// Check location range
if ($status === "present") {
    if ($student_lat === null || $student_lon === null) {
        echo json_encode(["success" => false, "message" => "Missing location data"]);
        exit();
    }

    $distance = haversineDistance($student_lat, $student_lon, $target_lat, $target_lon);
    if ($distance > 50) {
        echo json_encode(["success" => false, "message" => "You are too far from the lesson location"]);
        exit();
    }
}

// Enforce basic timing rules to reduce abuse:
// - "present" can only be marked for today and during the lesson time window.
// - "absent" can only be marked for past dates, or for today after lesson end.
$today_str = (new DateTimeImmutable('now'))->format('Y-m-d');
$lesson_start_dt = new DateTimeImmutable($today_str . ' ' . $lesson_loc['start_time']);
$lesson_end_dt = new DateTimeImmutable($today_str . ' ' . $lesson_loc['end_time']);
$now_dt = new DateTimeImmutable('now');

if ($status === 'present') {
    if ($attendance_date !== $today_str) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Present can only be marked on the lesson day"]);
        exit();
    }
    if ($now_dt < $lesson_start_dt || $now_dt > $lesson_end_dt) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Present can only be marked during the lesson time"]);
        exit();
    }
}

if ($status === 'absent') {
    if ($attendance_date > $today_str) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Absent cannot be marked for a future date"]);
        exit();
    }
    if ($attendance_date === $today_str && $now_dt <= $lesson_end_dt) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Absent can only be marked after the lesson ends"]);
        exit();
    }
}

// Save or update attendance
$sql = "
    INSERT INTO attendance (student_id, lesson_id, attendance_date, status, latitude, longitude)
    VALUES (?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE status = VALUES(status), latitude = VALUES(latitude), longitude = VALUES(longitude)
";
$stmt = $pdo->prepare($sql);

try {
    $stmt->execute([
        $student_id,
        $lesson_id,
        $attendance_date,
        $status,
        $student_lat,
        $student_lon
    ]);
    echo json_encode(["success" => true, "message" => "Attendance marked successfully"]);
} catch (PDOException $e) {
    error_log("mark_attendance.php DB error: " . $e->getMessage());
    echo json_encode(["success" => false, "message" => "Failed to mark attendance"]);
}
?>
