<?php
require 'db.php'; // shared PDO connection
require_once __DIR__ . '/admin_auth.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if (isAdminAuthRequired()) {
    requireAdminAuth();
}

$group_id = $_GET['group_id'] ?? null;
$start_date = $_GET['start_date'] ?? null;
$end_date = $_GET['end_date'] ?? null;
$subject = $_GET['subject'] ?? null;

if (!$group_id) {
    echo json_encode(["success" => false, "message" => "Missing group_id"]);
    exit();
}

// Get all students in the group
$students = [];
$stmt = $pdo->prepare("SELECT student_id, CONCAT(first_name, ' ', last_name) AS name FROM students WHERE group_id = ?");
$stmt->execute([$group_id]);
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $students[$row['student_id']] = $row['name'];
}

// Build lesson query
$lesson_sql = "SELECT * FROM lessons WHERE group_id = ?";
$params = [$group_id];

if ($subject) {
    $lesson_sql .= " AND subject_id = (SELECT subject_id FROM subjects WHERE name = ?)";
    $params[] = $subject;
}

$lesson_stmt = $pdo->prepare($lesson_sql);
$lesson_stmt->execute($params);
$lessons = $lesson_stmt->fetchAll(PDO::FETCH_ASSOC);

$sessions = [];

foreach ($lessons as $lesson) {
    $lesson_id = $lesson['lesson_id'];
    $dayOfWeek = $lesson['day_of_week'];
    $start = new DateTime($lesson['start_date']);
    $end = new DateTime($lesson['end_date']);

    if ($start_date) $start = max($start, new DateTime($start_date));
    if ($end_date) $end = min($end, new DateTime($end_date));

    $interval = new DateInterval('P1D');
    $period = new DatePeriod($start, $interval, $end->modify('+1 day'));

    foreach ($period as $date) {
        if ($date->format('l') !== $dayOfWeek) continue;

        $attendance_date = $date->format('Y-m-d');

        // 🔹 Get attendance for this lesson/date
        $att_stmt = $pdo->prepare("SELECT student_id, status FROM attendance WHERE lesson_id = ? AND attendance_date = ?");
        $att_stmt->execute([$lesson_id, $attendance_date]);
        $attendance = [];
        foreach ($att_stmt->fetchAll(PDO::FETCH_ASSOC) as $a) {
            $attendance[$a['student_id']] = $a['status'];
        }

        // Get subject name
        $subj_stmt = $pdo->prepare("SELECT name FROM subjects WHERE subject_id = ?");
        $subj_stmt->execute([$lesson['subject_id']]);
        $subj = $subj_stmt->fetchColumn() ?: 'N/A';

        $session_data = [
            'date' => $attendance_date,
            'subject' => $subj,
            'session' => []
        ];

        foreach ($students as $id => $name) {
            $session_data['session'][] = [
                'student' => $name,
                'status' => $attendance[$id] ?? 'Not Marked'
            ];
        }

        $sessions[] = $session_data;
    }
}

echo json_encode(["success" => true, "data" => $sessions]);
?>
