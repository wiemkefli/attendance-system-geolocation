<?php
require 'db.php'; // ✅ shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $queryType = $_GET['simple'] ?? null;

    if ($queryType === 'true') {
        // 🔹 Simplified version
        $stmt = $pdo->query("SELECT teacher_id, CONCAT(first_name, ' ', last_name) AS name, subject_id FROM teachers");
        $teachers = [];

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $row['teacher_id'] = (int)$row['teacher_id'];
            $row['subject_id'] = (int)$row['subject_id'];
            $teachers[] = $row;
        }

        echo json_encode($teachers);
        exit();
    } else {
        // 🔹 Full version
        $stmt = $pdo->query("
            SELECT t.teacher_id, t.first_name, t.last_name, t.email, t.phone, s.name AS subject_name, t.subject_id 
            FROM teachers t 
            LEFT JOIN subjects s ON t.subject_id = s.subject_id
        ");
        $teachers = [];

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $row['teacher_id'] = (int)$row['teacher_id'];
            $row['subject_id'] = (int)$row['subject_id'];
            $teachers[] = $row;
        }

        echo json_encode($teachers);
        exit();
    }
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    $first = $input['firstName'] ?? '';
    $last = $input['lastName'] ?? '';
    $email = $input['email'] ?? '';
    $phone = $input['phone'] ?? '';
    $subjectId = $input['subjectId'] ?? null;

    if ($first && $last && $email && $phone && $subjectId) {
        try {
            $stmt = $pdo->prepare("INSERT INTO teachers (first_name, last_name, email, phone, subject_id) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$first, $last, $email, $phone, $subjectId]);
            echo json_encode(["success" => true]);
        } catch (PDOException $e) {
            error_log("teacher_api.php POST insert error: " . $e->getMessage());
            echo json_encode(["success" => false, "message" => "Insert failed"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Missing data"]);
    }
    exit();
}

if ($method === 'DELETE') {
    $input = json_decode(file_get_contents("php://input"), true);
    $teacherId = $input['teacher_id'] ?? 0;

    if ($teacherId > 0) {
        $stmt = $pdo->prepare("DELETE FROM teachers WHERE teacher_id = ?");
        $stmt->execute([$teacherId]);
        echo json_encode(["success" => true]);
    } else {
        echo json_encode(["success" => false, "message" => "Invalid teacher ID"]);
    }
    exit();
}

echo json_encode(["success" => false, "message" => "Invalid request"]);
