<?php
require 'db.php'; // ✅ shared PDO connection
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? null;

// 🔹 Get students of a group
if ($action === 'students') {
    $groupId = intval($_GET['group_id'] ?? 0);
    $stmt = $pdo->prepare("SELECT student_id, first_name, last_name, email FROM students WHERE group_id = ?");
    $stmt->execute([$groupId]);
    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($students);
    exit();
}

// 🔹 Get all groups
if ($method === 'GET') {
    $stmt = $pdo->query("SELECT group_id, group_name FROM `groups` ORDER BY group_name ASC");
    $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($groups);
    exit();
}

// 🔹 Add new group
if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!$input) {
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $groupName = trim($input['group_name'] ?? '');
    if (!empty($groupName)) {
        try {
            $stmt = $pdo->prepare("INSERT INTO `groups` (group_name) VALUES (?)");
            $stmt->execute([$groupName]);
            echo json_encode(["success" => true, "message" => "Group created", "group_id" => $pdo->lastInsertId()]);
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => "Group already exists or DB error"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Missing group name"]);
    }
    exit();
}

// 🔹 Delete group
if ($method === 'DELETE') {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!$input) {
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $groupId = intval($input['group_id'] ?? 0);
    if ($groupId > 0) {
        $stmt = $pdo->prepare("DELETE FROM `groups` WHERE group_id = ?");
        $stmt->execute([$groupId]);
        echo json_encode(["success" => true, "message" => "Group deleted"]);
    } else {
        echo json_encode(["success" => false, "message" => "Invalid group ID"]);
    }
    exit();
}

echo json_encode(["success" => false, "message" => "Unsupported method"]);
exit();
