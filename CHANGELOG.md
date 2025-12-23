# Changelog

This project uses plan IDs (HP/MP/LP/DM) to track changes.

- `HP-001`: Added `attendance_api/.env.example` + `.env` loading; DB and JWT secret are no longer hardcoded.
- `HP-002`: Admin passwords are bcrypt-hashed (legacy plain-text is auto-upgraded on first login); seed updated in `attendance_db.sql`.
- `HP-003`: Admin login now issues a JWT; admin endpoints require the token when `ADMIN_AUTH_REQUIRED=true`.
- `HP-004` / `HP-005`: Attendance marking is guarded against `present -> absent` overwrites and validated against group/date/time rules.
- `HP-006`: `get_subjects_by_group.php` now returns a simple subject name list for the admin report filter.
- `MP-001` / `MP-003` / `MP-008`: Added a small Flutter `ApiClient`, disposed controllers, and fixed the default widget test to match the real UI.
- `MP-009`: Migrated remaining Flutter screens off direct `http` calls, centralized token handling in `flutter/lib/services/auth_storage.dart`, and introduced a typed `StudentDashboard` model.
- `MP-010`: Updated `attendance_api/composer.json` metadata so `composer validate` passes cleanly (CI-friendly); lock/vendor metadata refreshed.
- `LP-001`: Added a global Material 3 theme (`flutter/lib/theme/app_theme.dart`) and removed hardcoded AppBar/button colors for a more cohesive UI (light/dark supported via system).
- `LP-002`: Replaced remaining garbled/emoji-style UI labels with clear text + icons in the student timetable.
- `DM-001` / `DM-002`: Updated Flutter dependencies (lockfile) and removed unused `dart_jsonwebtoken`.
- `DM-003` / `DM-004` / `DM-005`: Targeted PHP 8.2+, upgraded `firebase/php-jwt` to v7, and adopted `vlucas/phpdotenv` (with fallback) for `.env` loading.
- `DM-006`: Bumped Dart SDK constraint to 3.10+ and refreshed the Flutter lockfile after moving to newer stable tooling.

