<?php
require 'db.php'; // shared PDO connection
require_once __DIR__ . '/admin_auth.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if (isAdminAuthRequired()) {
    requireAdminAuth();
}

$group_id = intval($_GET['group_id'] ?? 0);
$start_date = $_GET['start_date'] ?? null;
$end_date = $_GET['end_date'] ?? null;
$subject = $_GET['subject'] ?? null;

if ($group_id <= 0) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing group_id"]);
    exit();
}

$parseDate = function (?string $value): ?DateTimeImmutable {
    if ($value === null || $value === '') {
        return null;
    }
    $dt = DateTimeImmutable::createFromFormat('Y-m-d', $value);
    if (!$dt || $dt->format('Y-m-d') !== $value) {
        return null;
    }
    return $dt;
};

$startFilter = $parseDate($start_date);
if ($start_date !== null && $startFilter === null) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid start_date"]);
    exit();
}

$endFilter = $parseDate($end_date);
if ($end_date !== null && $endFilter === null) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid end_date"]);
    exit();
}

// Get all students in the group
$students = [];
$stmt = $pdo->prepare("SELECT student_id, CONCAT(first_name, ' ', last_name) AS name FROM students WHERE group_id = ?");
$stmt->execute([$group_id]);
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $students[(int)$row['student_id']] = $row['name'];
}

// Fetch lessons for the group (include subject name once)
$lessonSql = "
    SELECT
        l.lesson_id,
        l.day_of_week,
        l.start_date,
        l.end_date,
        s.name AS subject_name
    FROM lessons l
    JOIN subjects s ON l.subject_id = s.subject_id
    WHERE l.group_id = ?
";
$params = [$group_id];
if ($subject) {
    $lessonSql .= " AND s.name = ?";
    $params[] = $subject;
}

$lessonStmt = $pdo->prepare($lessonSql);
$lessonStmt->execute($params);
$lessons = $lessonStmt->fetchAll(PDO::FETCH_ASSOC);

if (!$lessons) {
    echo json_encode(["success" => true, "data" => []]);
    exit();
}

// Build session list and compute overall date range for a single attendance query.
$sessions = [];
$lessonIds = [];
$overallStart = null;
$overallEnd = null;

foreach ($lessons as $lesson) {
    $lesson_id = (int)$lesson['lesson_id'];
    $lessonIds[] = $lesson_id;

    $dayOfWeek = $lesson['day_of_week'];
    $lessonStart = DateTimeImmutable::createFromFormat('Y-m-d', $lesson['start_date']);
    $lessonEnd = DateTimeImmutable::createFromFormat('Y-m-d', $lesson['end_date']);
    if (!$lessonStart || !$lessonEnd) {
        continue;
    }

    $start = $lessonStart;
    $end = $lessonEnd;
    if ($startFilter && $startFilter > $start) {
        $start = $startFilter;
    }
    if ($endFilter && $endFilter < $end) {
        $end = $endFilter;
    }

    if ($end < $start) {
        continue;
    }

    $overallStart = $overallStart ? min($overallStart, $start) : $start;
    $overallEnd = $overallEnd ? max($overallEnd, $end) : $end;

    $period = new DatePeriod($start, new DateInterval('P1D'), $end->modify('+1 day'));
    foreach ($period as $date) {
        if ($date->format('l') !== $dayOfWeek) {
            continue;
        }

        $sessions[] = [
            'lesson_id' => $lesson_id,
            'date' => $date->format('Y-m-d'),
            'subject' => $lesson['subject_name'] ?: 'N/A',
        ];
    }
}

if (!$sessions || !$overallStart || !$overallEnd) {
    echo json_encode(["success" => true, "data" => []]);
    exit();
}

// Load attendance rows in bulk for all matching lessons and dates.
$placeholders = implode(',', array_fill(0, count($lessonIds), '?'));
$attendanceStmt = $pdo->prepare("
    SELECT lesson_id, attendance_date, student_id, status
    FROM attendance
    WHERE lesson_id IN ($placeholders)
      AND attendance_date BETWEEN ? AND ?
");

$attendanceParams = array_merge(
    $lessonIds,
    [$overallStart->format('Y-m-d'), $overallEnd->format('Y-m-d')]
);
$attendanceStmt->execute($attendanceParams);

$attendanceMap = [];
while ($row = $attendanceStmt->fetch(PDO::FETCH_ASSOC)) {
    $lid = (int)$row['lesson_id'];
    $date = $row['attendance_date'];
    $sid = (int)$row['student_id'];
    $attendanceMap[$lid][$date][$sid] = $row['status'];
}

// Build output sessions (same shape as before)
$output = [];
foreach ($sessions as $session) {
    $lesson_id = $session['lesson_id'];
    $date = $session['date'];

    $sessionData = [
        'date' => $date,
        'subject' => $session['subject'],
        'session' => [],
    ];

    foreach ($students as $id => $name) {
        $sessionData['session'][] = [
            'student' => $name,
            'status' => $attendanceMap[$lesson_id][$date][$id] ?? 'Not Marked',
        ];
    }

    $output[] = $sessionData;
}

echo json_encode(["success" => true, "data" => $output]);

