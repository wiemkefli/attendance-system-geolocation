<?php
require_once __DIR__ . '/env.php';
loadEnvFile(__DIR__ . '/.env');

require_once __DIR__ . '/vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

function requireStudentAuth(): array
{
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Missing token"]);
        exit();
    }

    $token = str_replace('Bearer ', '', $authHeader);
    $secret_key = getenv('JWT_SECRET') ?: 'your_super_secret_key';

    try {
        $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    } catch (Exception $e) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Invalid token"]);
        exit();
    }

    $student_id = isset($decoded->data->student_id) ? (int)$decoded->data->student_id : 0;
    $group_id = isset($decoded->data->group_id) ? (int)$decoded->data->group_id : 0;

    if ($student_id <= 0 || $group_id <= 0) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Invalid token payload"]);
        exit();
    }

    return [
        'student_id' => $student_id,
        'group_id' => $group_id,
        'token' => $token,
    ];
}

