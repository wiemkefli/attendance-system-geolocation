<?php
require 'db.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $sql = "
        SELECT lessons.lesson_id, subjects.name AS subject, lessons.day_of_week, 
               lessons.start_time, lessons.end_time, lessons.start_date, lessons.end_date,
               lessons.group_id, lessons.location_id,
               locations.latitude, locations.longitude, locations.name AS location_name,
               CONCAT(teachers.first_name, ' ', teachers.last_name) AS teacher_name,
               `groups`.group_name,
               subjects.name AS class_name
        FROM lessons
        JOIN teachers ON lessons.teacher_id = teachers.teacher_id
        JOIN `groups` ON lessons.group_id = `groups`.group_id
        JOIN locations ON lessons.location_id = locations.location_id
        JOIN subjects ON lessons.subject_id = subjects.subject_id
    ";

    $stmt = $pdo->query($sql);
    $lessons = [];

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $row['group_id'] = (int)$row['group_id'];
        $row['location_id'] = (int)$row['location_id'];
        $row['latitude'] = (float)$row['latitude'];
        $row['longitude'] = (float)$row['longitude'];
        $lessons[] = $row;
    }

    echo json_encode($lessons);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (isset($data['action']) && $data['action'] === 'delete') {
        $lesson_id = intval($data['lesson_id']);
        $stmt = $pdo->prepare("DELETE FROM lessons WHERE lesson_id = ?");
        $stmt->execute([$lesson_id]);
        echo json_encode(["success" => true]);
        exit();
    }

    // Insert lesson
    $subject_id = intval($data['subject_id']);
    $teacher_id = intval($data['teacher_id']);
    $group_id = intval($data['group_id']);
    $day_of_week = $data['day_of_week'];
    $start_time = $data['start_time'];
    $end_time = $data['end_time'];
    $start_date = $data['start_date'];
    $end_date = $data['end_date'];
    $location_id = intval($data['location_id']);

    $sql = "
        INSERT INTO lessons 
        (subject_id, teacher_id, group_id, day_of_week, start_time, end_time, start_date, end_date, location_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ";
    $stmt = $pdo->prepare($sql);

    try {
        $stmt->execute([
            $subject_id, $teacher_id, $group_id,
            $day_of_week, $start_time, $end_time,
            $start_date, $end_date, $location_id
        ]);
        echo json_encode(["success" => true]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
    exit();
}

echo json_encode(["success" => false, "message" => "Invalid request"]);
?>
