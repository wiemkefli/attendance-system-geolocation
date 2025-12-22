# Attendance System (Flutter + PHP + MySQL)

Mobile attendance app with an Admin panel and a Student panel. Students can view their timetable, mark attendance with geo-validation, and see attendance history. A background task can trigger local notifications if a class is about to start and the student is far from the class location.

## Repo Structure

- `flutter/` — Flutter app (UI + API client + background task)
- `attendance_api/` — PHP backend API (PDO + JWT)
- `attendance_api/composer.json` / `attendance_api/composer.lock` — PHP dependencies (JWT)
- `attendance_db.sql` — MySQL schema + seed data (drops/recreates `attendance_db`)

## Features

**Admin**
- Login
- Manage groups, students, teachers, locations, lessons
- Dashboard counts (students/teachers/lessons)
- Attendance report (filter by group/date/subject) and export to PDF (client-side)

**Student**
- JWT login
- Dashboard summary (attendance rate, subjects, upcoming classes, today classes)
- Timetable by date
- Mark attendance (`present`/`absent`) with geo checks
- Attendance history
- Profile + change password

**Background Notifications**
- Periodic task checks upcoming classes and triggers a local notification if the student is too far from the lesson location.

## Prerequisites

- Flutter SDK (Dart 3.4+)
- PHP 8+ (works with PHP built-in server)
- MySQL 8.x (or compatible)
- Android Emulator or device (for geolocation + notifications)

## Quick Start

### 1) Create the database

`attendance_db.sql` will drop and recreate the database named `attendance_db`.

Option A (CLI):

```bash
mysql -u root -p < attendance_db.sql
```

Option B (MySQL Workbench / phpMyAdmin):
- Open `attendance_db.sql`
- Run the script

### 2) Start the backend (PHP API)

From the repo root:

```bash
cd attendance_api
composer install
cd ..
```

Then start the built-in PHP server:

```bash
php -S 0.0.0.0:8000 -t attendance_api
```

The API will be available at:
- `http://localhost:8000/admin_login.php`
- `http://localhost:8000/student_login.php`
- etc.

#### Configure DB credentials

Create `attendance_api/.env` from `attendance_api/.env.example` and set:

```bash
DB_HOST=localhost
DB_NAME=attendance_db
DB_USER=root
DB_PASS=...
JWT_SECRET=...
```

### 3) Run the Flutter app

```bash
cd flutter
flutter pub get
flutter run
```

#### API base URL (important)

The Flutter app uses `flutter/lib/config/api_config.dart` and defaults to:

- Android emulator: `http://10.0.2.2:8000`

Override the backend base URL at runtime:

```bash
flutter run --dart-define=API_BASE_URL=http://<host>:8000
```

If your PHP server is hosted behind a path (example: `/attendance_api`):

```bash
flutter run --dart-define=API_BASE_URL=http://<host>:8000/attendance_api
```

## Default Seed Credentials

From `attendance_db.sql`:

- **Admin**: `admin / admin123` (stored as plain text in DB; change for real usage)
- **Student**: `alice@example.com / password123` (stored as a bcrypt hash)

## Backend API

Base URL examples:
- Emulator: `http://10.0.2.2:8000`
- Localhost: `http://localhost:8000`

### Auth

- Student auth uses JWT with `Authorization: Bearer <token>`
- Admin endpoints in this repo do not use JWT (admin login returns only success/message)

⚠️ The JWT secret can be configured via `attendance_api/.env` using `JWT_SECRET`. If not set, the API falls back to the legacy default `your_super_secret_key` (dev only).

### Endpoints (as implemented)

**Auth**
- `POST /admin_login.php` — JSON: `{ "username": "...", "password": "..." }`
- `POST /student_login.php` — JSON: `{ "email": "...", "password": "..." }` → returns `token`, `group_id`

**Admin dashboard**
- `POST /admin_dashboard.php` — (optional) form field `date=YYYY-MM-DD` (defaults to today)

**Catalog**
- `GET /subjects_api.php`

**Groups**
- `GET /group_api.php`
- `GET /group_api.php?action=students&group_id=<id>`
- `POST /group_api.php` — JSON: `{ "group_name": "..." }`
- `DELETE /group_api.php` — JSON: `{ "group_id": 1 }`

**Students**
- `GET /student_api.php` — returns `{ students: [...], groups: [...] }`
- `POST /student_api.php` — JSON: `{ "firstName": "...", "lastName": "...", "email": "...", "groupId": 1, "password": "..." }`
- `DELETE /student_api.php` — JSON: `{ "student_id": 1 }`

**Teachers**
- `GET /teacher_api.php`
- `GET /teacher_api.php?simple=true`
- `POST /teacher_api.php` — JSON: `{ "firstName": "...", "lastName": "...", "email": "...", "phone": "...", "subjectId": 1 }`
- `DELETE /teacher_api.php` — JSON: `{ "teacher_id": 1 }`

**Locations**
- `GET /location_api.php`
- `POST /location_api.php` — JSON: `{ "name": "...", "latitude": 0.0, "longitude": 0.0 }`
- `DELETE /location_api.php` — JSON: `{ "location_id": 1 }`

**Lessons**
- `GET /lessons_api.php` — returns lessons joined with group/teacher/subject/location
- `POST /lessons_api.php` — create lesson (see payload in `attendance_api/lessons_api.php`)
- `POST /lessons_api.php` — delete lesson: `{ "action": "delete", "lesson_id": 1 }`

**Student (JWT-protected)**
- `POST /student_dashboard.php` — JSON: `{ "date": "YYYY-MM-DD" }`
- `GET /student_profile.php`
- `POST /change_password.php` — JSON: `{ "new_password": "..." }`
- `GET /get_attendance_history.php`
- `GET /get_attendance_status.php?lesson_id=<id>&date=YYYY-MM-DD`
- `POST /mark_attendance.php` — JSON: `{ "lesson_id": 1, "attendance_date": "YYYY-MM-DD", "status": "present|absent", "latitude": 0.0, "longitude": 0.0 }`

**Reporting**
- `GET /get_attendance_summary.php?group_id=<id>[&subject=...&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD]`

## Database

The backend expects a MySQL database named `attendance_db` containing:
- `admin`
- `groups`
- `subjects`
- `teachers`
- `locations`
- `lessons`
- `students`
- `attendance` (unique per `student_id + lesson_id + attendance_date`)

See `attendance_db.sql` for the full schema.

## Notifications & Background Task

On student login, the app registers:
- A one-off task (initial delay ~30s)
- A periodic task (every 15 minutes)

Implementation: `flutter/lib/services/background_task.dart`

Behavior summary:
- Fetches today’s lessons
- If the next class starts within 15 minutes and distance > 100m → triggers a local notification

## Common Gotchas

- **Android emulator vs device networking**: `10.0.2.2` works only on the Android emulator. For a physical device, use your machine’s LAN IP (example: `http://192.168.1.10:8000`) and ensure the device can reach it.
- **Hard-coded credentials/secrets**:
  - DB credentials and JWT secret can be set in `attendance_api/.env` (see `attendance_api/.env.example`)
  - Admin passwords are compared as plain text (see `attendance_api/admin_login.php`)
- **Composer install location**: PHP dependencies are expected at `attendance_api/vendor/`; run `composer install` inside `attendance_api/` (not the repo root).
- **`export_attendance_pdf.php`**: references `tcpdf/tcpdf.php`, but `attendance_api/tcpdf/` is not present in this repo; the Flutter app exports PDFs client-side instead.
- **`get_subjects_by_group.php`**: the Flutter admin report page (`flutter/lib/screens/admin/attendance_report.dart`) expects this endpoint to return a simple list of subject names, but the current PHP file returns a `{"success": true, "data": ...}` session-style payload.

## Development Notes

- Flutter API base URL is centralized in `flutter/lib/config/api_config.dart`.
- JWT is decoded client-side via `jwt_decoder` for convenience, but the backend is the source of truth.

## License

No license file is included in this repository. Add one if you plan to distribute the project.
