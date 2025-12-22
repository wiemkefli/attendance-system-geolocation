<?php
require 'db.php'; // shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$group_id = intval($_GET['group_id'] ?? 0);

// Used by the Flutter admin report screen to populate the subject filter dropdown.
// Return a simple JSON array of subject names for the given group_id.
if ($group_id <= 0) {
    http_response_code(400);
    echo json_encode([]);
    exit();
}

try {
    $stmt = $pdo->prepare("
        SELECT DISTINCT s.name
        FROM lessons l
        JOIN subjects s ON l.subject_id = s.subject_id
        WHERE l.group_id = ?
        ORDER BY s.name ASC
    ");
    $stmt->execute([$group_id]);

    $subjects = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $subjects[] = $row['name'];
    }

    echo json_encode($subjects);
} catch (PDOException $e) {
    error_log("get_subjects_by_group.php DB error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([]);
}
?>
