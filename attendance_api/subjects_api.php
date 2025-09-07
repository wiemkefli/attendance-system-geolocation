<?php
require 'db.php'; // shared PDO connection

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

try {
    $stmt = $pdo->query("SELECT subject_id, name FROM subjects");
    $subjects = [];

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $row['subject_id'] = (int)$row['subject_id']; // Ensure subject_id is returned as integer
        $subjects[] = $row;
    }

    echo json_encode($subjects);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
