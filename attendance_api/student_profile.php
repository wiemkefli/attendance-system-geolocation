<?php
require 'vendor/autoload.php';
require 'db.php'; // ✅ use shared PDO connection

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization");
header("Content-Type: application/json");

$secret_key = "your_super_secret_key";

// ✅ Token handling
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

// ✅ Fetch student profile data
$sql = "
    SELECT s.first_name, s.last_name, s.email, g.group_name
    FROM students s
    LEFT JOIN `groups` g ON s.group_id = g.group_id
    WHERE s.student_id = ?
";

$stmt = $pdo->prepare($sql);
$stmt->execute([$student_id]);

$row = $stmt->fetch(PDO::FETCH_ASSOC);
if ($row) {
    echo json_encode($row);
} else {
    echo json_encode(["success" => false, "message" => "Student not found"]);
}
?>
