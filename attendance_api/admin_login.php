<?php
require 'vendor/autoload.php';
require 'db.php'; // ✅ shared PDO connection
require_once __DIR__ . '/jwt_secret.php';

use Firebase\JWT\JWT;

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);

    $username = $input['username'] ?? '';
    $password = $input['password'] ?? '';

    if (!empty($username) && !empty($password)) {
        $stmt = $pdo->prepare("SELECT * FROM admin WHERE username = ?");
        $stmt->execute([$username]);
        $admin = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($admin) {
            $storedPassword = $admin['password'] ?? '';
            $passwordInfo = password_get_info($storedPassword);
            $secret_key = getJwtSecretKey();

            $issueToken = function () use ($admin, $secret_key) {
                $payload = [
                    "iat" => time(),
                    "exp" => time() + (60 * 60 * 8),
                    "data" => [
                        "admin_id" => (int)$admin['admin_id'],
                        "username" => $admin['username'],
                        "role" => "admin",
                    ],
                ];

                return JWT::encode($payload, $secret_key, 'HS256');
            };

            if (($passwordInfo['algo'] ?? 0) !== 0) {
                if (password_verify($password, $storedPassword)) {
                    echo json_encode([
                        "success" => true,
                        "message" => "Admin login successful",
                        "token" => $issueToken(),
                    ]);
                } else {
                    echo json_encode(["success" => false, "message" => "Incorrect password"]);
                }
                exit();
            }

            // Legacy plain-text support (auto-migrate to a hash on first successful login).
            if ($password === $storedPassword) {
                $newHash = password_hash($password, PASSWORD_DEFAULT);
                try {
                    $update = $pdo->prepare("UPDATE admin SET password = ? WHERE admin_id = ?");
                    $update->execute([$newHash, (int)$admin['admin_id']]);
                } catch (PDOException $e) {
                    error_log("admin_login.php password upgrade failed: " . $e->getMessage());
                }

                echo json_encode([
                    "success" => true,
                    "message" => "Admin login successful",
                    "token" => $issueToken(),
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Incorrect password"]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Admin not found"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Missing username or password"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid request method"]);
}
