<?php
require 'db.php'; // shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // 🔹 Fetch students with group name
        $studentsStmt = $pdo->query("
            SELECT s.student_id, s.first_name, s.last_name, s.email, s.group_id, g.group_name 
            FROM students s
            LEFT JOIN `groups` g ON s.group_id = g.group_id
        ");
        $students = $studentsStmt->fetchAll(PDO::FETCH_ASSOC);

        // 🔹 Fetch groups
        $groupsStmt = $pdo->query("SELECT group_id, group_name FROM `groups` ORDER BY group_name ASC");
        $groups = $groupsStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["students" => $students, "groups" => $groups]);
        break;

    case 'POST':
        $input = json_decode(file_get_contents("php://input"), true);

        if (!$input) {
            echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
            exit();
        }

        $firstName = trim($input['firstName'] ?? '');
        $lastName = trim($input['lastName'] ?? '');
        $email = trim($input['email'] ?? '');
        $groupId = intval($input['groupId'] ?? 0);
        $password = $input['password'] ?? '';

        if (!empty($firstName) && !empty($lastName) && !empty($email) && $groupId > 0 && !empty($password)) {
            $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
            try {
                $stmt = $pdo->prepare("INSERT INTO students (first_name, last_name, email, group_id, password) VALUES (?, ?, ?, ?, ?)");
                $stmt->execute([$firstName, $lastName, $email, $groupId, $hashedPassword]);
                echo json_encode(["success" => true, "message" => "Student added"]);
            } catch (PDOException $e) {
                echo json_encode(["success" => false, "message" => "Error adding student: " . $e->getMessage()]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Missing or invalid fields"]);
        }
        break;

    case 'DELETE':
        $input = json_decode(file_get_contents("php://input"), true);
        $studentId = intval($input['student_id'] ?? 0);

        if ($studentId > 0) {
            $stmt = $pdo->prepare("DELETE FROM students WHERE student_id = ?");
            $stmt->execute([$studentId]);
            echo json_encode(["success" => true, "message" => "Student deleted"]);
        } else {
            echo json_encode(["success" => false, "message" => "Invalid student ID"]);
        }
        break;

    default:
        echo json_encode(["success" => false, "message" => "Unsupported method"]);
        break;
}
