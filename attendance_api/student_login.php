<?php
require 'vendor/autoload.php'; // Needed for JWT
require 'db.php'; // use shared PDO connection

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$secret_key = getenv('JWT_SECRET') ?: 'your_super_secret_key';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);

    $email = $input['email'] ?? '';
    $password = $input['password'] ?? '';

    if (!empty($email) && !empty($password)) {
        $stmt = $pdo->prepare("SELECT * FROM students WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            $hashedPassword = $user['password'];

            if (password_verify($password, $hashedPassword)) {
                $payload = [
                    "iss" => "http://localhost",
                    "aud" => "http://localhost",
                    "iat" => time(),
                    "exp" => time() + (60 * 60), // 1 hour
                    "data" => [
                        "student_id" => (int)$user['student_id'],
                        "group_id" => (int)$user['group_id'],
                        "email" => $user['email']
                    ]
                ];

                $jwt = JWT::encode($payload, $secret_key, 'HS256');

                echo json_encode([
                    "success" => true,
                    "message" => "Login successful",
                    "token" => $jwt,
                    "group_id" => (int)$user['group_id'] 
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Incorrect password"]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Student not found"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Missing email or password"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid request"]);
}
?>
