<?php
require 'db.php'; // shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];

// 🔹 Get all locations
if ($method === 'GET') {
    $stmt = $pdo->query("SELECT location_id, name, latitude, longitude FROM locations ORDER BY name ASC");
    $locations = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($locations);
    exit();
}

// 🔹 Add new location
if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!$input) {
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $name = trim($input['name'] ?? '');
    $latitude = $input['latitude'] ?? null;
    $longitude = $input['longitude'] ?? null;

    if (!empty($name) && is_numeric($latitude) && is_numeric($longitude)) {
        try {
            $stmt = $pdo->prepare("INSERT INTO locations (name, latitude, longitude) VALUES (?, ?, ?)");
            $stmt->execute([$name, $latitude, $longitude]);
            echo json_encode([
                "success" => true,
                "message" => "Location created",
                "location_id" => $pdo->lastInsertId()
            ]);
        } catch (PDOException $e) {
            error_log("location_api.php POST insert error: " . $e->getMessage());
            echo json_encode(["success" => false, "message" => "DB error or duplicate location"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Missing or invalid fields"]);
    }
    exit();
}

// 🔹 Delete location
if ($method === 'DELETE') {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!$input) {
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $locationId = intval($input['location_id'] ?? 0);
    if ($locationId > 0) {
        $stmt = $pdo->prepare("DELETE FROM locations WHERE location_id = ?");
        $stmt->execute([$locationId]);
        echo json_encode(["success" => true, "message" => "Location deleted"]);
    } else {
        echo json_encode(["success" => false, "message" => "Invalid location ID"]);
    }
    exit();
}

echo json_encode(["success" => false, "message" => "Unsupported method"]);
exit();
