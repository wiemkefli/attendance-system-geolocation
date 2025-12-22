<?php
require_once __DIR__ . '/env.php';
loadEnvFile(__DIR__ . '/.env');

require_once __DIR__ . '/vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

function isAdminAuthRequired(): bool
{
    $raw = getenv('ADMIN_AUTH_REQUIRED');
    if ($raw === false) {
        return true;
    }

    $value = strtolower(trim((string)$raw));
    return !in_array($value, ['0', 'false', 'no', 'off'], true);
}

function requireAdminAuth(): object
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

    $role = $decoded->data->role ?? null;
    if ($role !== 'admin') {
        http_response_code(403);
        echo json_encode(["success" => false, "message" => "Forbidden"]);
        exit();
    }

    return $decoded;
}

