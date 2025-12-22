<?php
require 'vendor/autoload.php';
require 'db.php'; // use shared PDO

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = getenv('JWT_SECRET') ?: 'your_super_secret_key';

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
    $student_id = $decoded->data->student_id;
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Invalid token"]);
    exit();
}

// Read POST data
$data = json_decode(file_get_contents("php://input"), true);
$lesson_id = intval($data["lesson_id"]);
$attendance_date = $data["attendance_date"];
$status = $data["status"];
$student_lat = isset($data["latitude"]) ? floatval($data["latitude"]) : null;
$student_lon = isset($data["longitude"]) ? floatval($data["longitude"]) : null;

// Get lesson location
$loc_sql = "
    SELECT locations.latitude, locations.longitude
    FROM lessons
    JOIN locations ON lessons.location_id = locations.location_id
    WHERE lessons.lesson_id = ?
";
$loc_stmt = $pdo->prepare($loc_sql);
$loc_stmt->execute([$lesson_id]);
$lesson_loc = $loc_stmt->fetch(PDO::FETCH_ASSOC);

if (!$lesson_loc) {
    echo json_encode(["success" => false, "message" => "Lesson not found"]);
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
