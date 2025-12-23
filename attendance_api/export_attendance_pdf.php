<?php
require 'db.php'; // shared PDO
require_once __DIR__ . '/admin_auth.php';

header("Access-Control-Allow-Origin: *");

if (isAdminAuthRequired()) {
    requireAdminAuth();
}

$tcpdfPath = __DIR__ . '/tcpdf/tcpdf.php';
if (!is_file($tcpdfPath)) {
    header("Content-Type: application/json");
    http_response_code(501);
    echo json_encode([
        "success" => false,
        "message" =>
            "Server-side PDF export is not installed (TCPDF missing). Use the Flutter app's PDF export instead.",
    ]);
    exit();
}

require_once $tcpdfPath;

$group_id = $_GET['group_id'] ?? null;
$start_date = $_GET['start_date'] ?? null;
$end_date = $_GET['end_date'] ?? null;

if (!$group_id) {
    header("Content-Type: application/json");
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing group_id"]);
    exit();
}

// Fetch students
$students = [];
$stmt = $pdo->prepare("SELECT student_id, CONCAT(first_name, ' ', last_name) AS name FROM students WHERE group_id = ?");
$stmt->execute([$group_id]);
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $students[$row['student_id']] = $row['name'];
}

// Setup PDF
$pdf = new TCPDF();
$pdf->AddPage();
$pdf->SetFont('helvetica', '', 12);
$pdf->Write(0, 'Attendance Report', '', 0, 'L', true, 0, false, false, 0);
$pdf->Ln(4);

// Fetch lessons
$lessons_stmt = $pdo->prepare("SELECT * FROM lessons WHERE group_id = ?");
$lessons_stmt->execute([$group_id]);
$lessons = $lessons_stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($lessons as $lesson) {
    $lesson_id = $lesson['lesson_id'];

    // Get subject name
    $sub_stmt = $pdo->prepare("SELECT name FROM subjects WHERE subject_id = ?");
    $sub_stmt->execute([$lesson['subject_id']]);
    $subject = $sub_stmt->fetchColumn();

    $dayOfWeek = $lesson['day_of_week'];
    $start = new DateTime($lesson['start_date']);
    $end = new DateTime($lesson['end_date']);

    if ($start_date) {
        $start = max($start, new DateTime($start_date));
    }
    if ($end_date) {
        $end = min($end, new DateTime($end_date));
    }

    $interval = new DateInterval('P1D');
    $period = new DatePeriod($start, $interval, $end->modify('+1 day'));

    foreach ($period as $date) {
        if ($date->format('l') !== $dayOfWeek) {
            continue;
        }

        $date_str = $date->format('Y-m-d');
        $pdf->SetFont('', 'B');
        $pdf->Cell(0, 10, "$date_str - $subject", 0, 1);
        $pdf->SetFont('', '');

        // Fetch attendance
        $att_stmt = $pdo->prepare("SELECT student_id, status FROM attendance WHERE lesson_id = ? AND attendance_date = ?");
        $att_stmt->execute([$lesson_id, $date_str]);
        $att = [];
        foreach ($att_stmt->fetchAll(PDO::FETCH_ASSOC) as $a) {
            $att[$a['student_id']] = $a['status'];
        }

        foreach ($students as $id => $name) {
            $status = $att[$id] ?? 'Not Marked';
            $pdf->Cell(90, 8, $name, 1);
            $pdf->Cell(40, 8, $status, 1);
            $pdf->Ln();
        }

        $pdf->Ln(4);
    }
}

$pdf->Output('attendance_report.pdf', 'I');
