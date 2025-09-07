<?php
require 'vendor/autoload.php';
require 'db.php'; // use shared PDO

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = "your_super_secret_key";

// Decode JWT
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

// Get lesson and date
$lesson_id = intval($_GET['lesson_id'] ?? 0);
$date = $_GET['date'] ?? '';

if ($lesson_id <= 0 || empty($date)) {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
    exit();
}

// Query attendance
$sql = "SELECT status FROM attendance WHERE student_id = ? AND lesson_id = ? AND attendance_date = ?";
$stmt = $pdo->prepare($sql);
$stmt->execute([$student_id, $lesson_id, $date]);

$row = $stmt->fetch(PDO::FETCH_ASSOC);
if ($row) {
    echo json_encode(["success" => true, "status" => $row['status']]);
} else {
    echo json_encode(["success" => true, "status" => null]);
}
?>
