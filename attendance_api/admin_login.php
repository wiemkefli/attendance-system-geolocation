<?php
require 'db.php'; // ✅ shared PDO connection

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
            // If using hashed passwords:
            // if (password_verify($password, $admin['password'])) { ...

            // If storing plain text passwords (NOT RECOMMENDED):
            if ($password === $admin['password']) {
                echo json_encode(["success" => true, "message" => "Admin login successful"]);
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
