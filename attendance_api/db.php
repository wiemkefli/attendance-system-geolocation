<?php
try {
    $pdo = new PDO("mysql:host=localhost;dbname=attendance_db", "root", "123456");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit();
}
?>
