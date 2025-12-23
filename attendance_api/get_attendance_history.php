<?php
require 'vendor/autoload.php';
require 'db.php'; // ✅ shared PDO connection
require_once __DIR__ . '/jwt_secret.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization");
header("Content-Type: application/json");

$secret_key = getJwtSecretKey();

// 🔐 Extract and decode JWT
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

// 📚 Fetch attendance history
$query = "
  SELECT 
    a.attendance_date, 
    a.status,
    s.name AS subject,
    l.day_of_week, 
    l.start_time, 
    l.end_time 
  FROM attendance a
  JOIN lessons l ON a.lesson_id = l.lesson_id
  JOIN subjects s ON l.subject_id = s.subject_id
  WHERE a.student_id = ?
  ORDER BY a.attendance_date DESC
";

$stmt = $pdo->prepare($query);
$stmt->execute([$student_id]);

$data = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $data[] = $row;
}

echo json_encode(["success" => true, "data" => $data]);
?>
