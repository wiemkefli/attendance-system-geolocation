-- Bootstrap schema for attendance_db
-- Compatible with MySQL 8.x
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS attendance_db;
CREATE DATABASE attendance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE attendance_db;

-- Admin users (plain password check in admin_login.php)
CREATE TABLE admin (
  admin_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  PRIMARY KEY (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Student groups
CREATE TABLE `groups` (
  group_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_name VARCHAR(150) NOT NULL UNIQUE,
  PRIMARY KEY (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Subjects catalog
CREATE TABLE subjects (
  subject_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL UNIQUE,
  PRIMARY KEY (subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Teachers
CREATE TABLE teachers (
  teacher_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(191) NOT NULL UNIQUE,
  phone VARCHAR(50) NOT NULL,
  subject_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (teacher_id),
  KEY idx_teachers_subject (subject_id),
  CONSTRAINT fk_teachers_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Locations used for geo checks
CREATE TABLE locations (
  location_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL UNIQUE,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  PRIMARY KEY (location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Lessons / classes
CREATE TABLE lessons (
  lesson_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  subject_id INT UNSIGNED NOT NULL,
  teacher_id INT UNSIGNED NOT NULL,
  group_id INT UNSIGNED NOT NULL,
  day_of_week VARCHAR(20) NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  location_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (lesson_id),
  KEY idx_lessons_subject (subject_id),
  KEY idx_lessons_teacher (teacher_id),
  KEY idx_lessons_group (group_id),
  KEY idx_lessons_location (location_id),
  CONSTRAINT fk_lessons_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lessons_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lessons_group FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_lessons_location FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Students (password hashed with PASSWORD_DEFAULT / bcrypt)
CREATE TABLE students (
  student_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(191) NOT NULL UNIQUE,
  group_id INT UNSIGNED NOT NULL,
  password VARCHAR(255) NOT NULL,
  PRIMARY KEY (student_id),
  KEY idx_students_group (group_id),
  CONSTRAINT fk_students_group FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Attendance records (unique per student/lesson/date)
CREATE TABLE attendance (
  attendance_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id INT UNSIGNED NOT NULL,
  lesson_id INT UNSIGNED NOT NULL,
  attendance_date DATE NOT NULL,
  status ENUM('present','absent','Not Marked') NOT NULL DEFAULT 'Not Marked',
  latitude DOUBLE NULL,
  longitude DOUBLE NULL,
  PRIMARY KEY (attendance_id),
  UNIQUE KEY uniq_attendance (student_id, lesson_id, attendance_date),
  KEY idx_attendance_student (student_id),
  KEY idx_attendance_lesson (lesson_id),
  CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_attendance_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed data
INSERT INTO admin (username, password) VALUES
  ('admin', '$2y$12$WVIm56H.5m1MnnEfk0CYSO1.MJf5s3Q4egzBsOD9kWtgtwX0Aub6O');

INSERT INTO `groups` (group_name) VALUES
  ('Group A'),
  ('Group B');

INSERT INTO subjects (name) VALUES
  ('Math'),
  ('Physics'),
  ('English');

INSERT INTO locations (name, latitude, longitude) VALUES
  ('Main Hall', 40.712776, -74.005974),
  ('Science Lab', 40.713500, -74.006500);

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO teachers (first_name, last_name, email, phone, subject_id) VALUES
  ('John', 'Doe', 'john.doe@example.com', '+1-555-1000', 1),
  ('Jane', 'Smith', 'jane.smith@example.com', '+1-555-2000', 2);

INSERT INTO lessons (subject_id, teacher_id, group_id, day_of_week, start_time, end_time, start_date, end_date, location_id) VALUES
  (1, 1, 1, 'Monday', '09:00:00', '10:00:00', '2024-09-01', '2025-06-30', 1),
  (2, 2, 1, 'Wednesday', '11:00:00', '12:30:00', '2024-09-01', '2025-06-30', 2);

-- Student password is "password123" (bcrypt hash generated via PHP password_hash)
INSERT INTO students (first_name, last_name, email, group_id, password) VALUES
  ('Alice', 'Johnson', 'alice@example.com', 1, '$2y$12$p3rnjEvwSHHr5FVf1mgce.vGsz.eysvAcPKkm94ALMyjt/YHd3l9G');

-- Example attendance row (present for first lesson on a sample date)
INSERT INTO attendance (student_id, lesson_id, attendance_date, status, latitude, longitude) VALUES
  (1, 1, '2024-09-02', 'present', 40.712800, -74.005900);
