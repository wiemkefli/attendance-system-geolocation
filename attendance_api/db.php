<?php
require_once __DIR__ . '/env.php';
loadEnvFile(__DIR__ . '/.env');

try {
    $host = getenv('DB_HOST') ?: 'localhost';
    $dbName = getenv('DB_NAME') ?: 'attendance_db';
    $username = getenv('DB_USER') ?: 'root';
    $password = getenv('DB_PASS') ?: '123456';
    $charset = getenv('DB_CHARSET') ?: 'utf8mb4';

    $dsn = "mysql:host={$host};dbname={$dbName};charset={$charset}";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    if (!headers_sent()) {
        header("Content-Type: application/json; charset=UTF-8");
    }
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit();
}
?>
