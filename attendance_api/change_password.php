<?php
require 'vendor/autoload.php';
require 'db.php'; // ✅ shared PDO connection

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = getenv('JWT_SECRET') ?: 'your_super_secret_key';

// ✅ Get token from Authorization header
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

// ✅ Get new password
$data = json_decode(file_get_contents("php://input"), true);
$newPassword = $data['new_password'] ?? '';

if (strlen($newPassword) < 8) {
    echo json_encode(["success" => false, "message" => "Password must be at least 8 characters"]);
    exit();
}

$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

// ✅ Update in database
$sql = "UPDATE students SET password = ? WHERE student_id = ?";
$stmt = $pdo->prepare($sql);

try {
    $stmt->execute([$hashedPassword, $student_id]);
    echo json_encode(["success" => true, "message" => "Password updated"]);
} catch (PDOException $e) {
    error_log("change_password.php DB error: " . $e->getMessage());
    echo json_encode(["success" => false, "message" => "Update failed"]);
}
?>
