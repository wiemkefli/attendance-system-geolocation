<?php
require 'db.php'; // ✅ shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $date = $_POST['date'] ?? date('Y-m-d');

    try {
        // Total students
        $stmt = $pdo->query("SELECT COUNT(*) AS students FROM students");
        $students = $stmt->fetchColumn();

        // Total teachers
        $stmt = $pdo->query("SELECT COUNT(*) AS teachers FROM teachers");
        $teachers = $stmt->fetchColumn();

        // Total lessons
        $stmt = $pdo->query("SELECT COUNT(*) AS lessons FROM lessons");
        $lessons = $stmt->fetchColumn();

        // Students present today
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM attendance WHERE attendance_date = ? AND status = 'present'");
        $stmt->execute([$date]);
        $present_today = $stmt->fetchColumn();

        // Today's attendance list
        $stmt = $pdo->prepare("
            SELECT s.first_name, s.last_name, s.email AS contact, a.status
            FROM attendance a
            JOIN students s ON a.student_id = s.student_id
            WHERE a.attendance_date = ?
        ");
        $stmt->execute([$date]);
        $attendance_today = [];

        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $attendance_today[] = [
                "name" => $row['first_name'] . ' ' . $row['last_name'],
                "contact" => $row['contact'],
                "status" => ucfirst($row['status']),
                "today" => "Yes"
            ];
        }

        // Teacher list (subject = N/A placeholder)
        $stmt = $pdo->query("SELECT first_name, last_name FROM teachers");
        $teacher_list = [];

        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $teacher_list[] = [
                "name" => $row['first_name'] . ' ' . $row['last_name'],
                "subject" => "N/A"
            ];
        }

        echo json_encode([
            "success" => true,
            "students" => (int)$students,
            "teachers" => (int)$teachers,
            "lessons" => (int)$lessons,
            "present_today" => (int)$present_today,
            "attendance_today" => $attendance_today,
            "teacher_list" => $teacher_list
        ]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }

    exit();
}

echo json_encode(["success" => false, "message" => "Invalid request method"]);
exit();
