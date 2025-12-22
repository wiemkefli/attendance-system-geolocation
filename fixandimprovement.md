# Fix & Improvement Plan

## 0. Quick Summary
- **What this project is:** A Flutter mobile attendance app with **Admin** and **Student** panels backed by a **vanilla PHP + MySQL** API. Students authenticate via **JWT**, can mark attendance using **geo-distance**, view timetable/history, and receive **background notifications** (WorkManager) if a class is soon and they are far away.
- **Major issues found:**
  - **Security:** Hardcoded DB creds + hardcoded JWT secret; **admin auth is plain-text** and admin CRUD endpoints are **not authenticated at all**.
  - **Data integrity:** Student timetable auto-posts `absent` records and the backend allows updates, which can **overwrite previously “present” attendance with “absent”**.
  - **Broken endpoint:** `attendance_api/export_attendance_pdf.php` references `tcpdf/` which is not present.
  - **Maintainability:** Flutter screens do direct HTTP calls (no API layer/models), duplicated navigation drawers, controllers not disposed, and inconsistent error handling.
  - **Performance:** Students fetch **all lessons for all groups** and then do per-lesson attendance status calls (N+1 network requests).
- **Biggest wins:**
  - Add `.env` + centralized config (DB + JWT) and stop hardcoding secrets.
  - Add **admin JWT** and protect admin endpoints.
  - Fix attendance overwrite risk by enforcing rules server-side and removing the client “auto-absent overwrite” behavior.
  - Introduce a small Flutter `ApiClient` + typed models and migrate screens incrementally.

---

## 1. High Priority (Security / Data Loss / Broken Builds)

### HP-001
- **Problem (what/where):** Hardcoded DB credentials in `attendance_api/db.php` and hardcoded JWT secret string in multiple PHP files (`attendance_api/*`).
- **Why it matters:** Credential leakage and trivial compromise of tokens; changing secrets requires editing many files and risks drift.
- **Proposed fix (exact approach):**
  - Add `attendance_api/.env.example` (placeholders) and load env vars via `vlucas/phpdotenv`.
  - Create a single config loader (e.g. `attendance_api/bootstrap.php`) that initializes `$pdo`, reads env, and exposes `JWT_SECRET`.
  - Keep safe defaults for local dev (but loudly documented) so project stays runnable.
- **Files involved (list):** `attendance_api/db.php`, `attendance_api/*.php`, `attendance_api/composer.json`, `attendance_api/.env.example`, `README.md`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - `composer install` and `php -S 0.0.0.0:8000 -t attendance_api`
  - Confirm login works with env-driven DB creds and JWT secret.

### HP-002
- **Problem (what/where):** Admin passwords stored and checked as **plain text** (`attendance_db.sql`, `attendance_api/admin_login.php`).
- **Why it matters:** Immediate account compromise if DB leaks; also prevents secure admin auth expansion.
- **Proposed fix (exact approach):**
  - Migrate admin passwords to `password_hash()` and verify with `password_verify()`.
  - Update seed data in `attendance_db.sql` to store a bcrypt hash (and update README default creds note).
- **Files involved (list):** `attendance_db.sql`, `attendance_api/admin_login.php`, `README.md`
- **Risk level:** Medium (requires coordinating seed/login expectations)
- **Verification steps (how to confirm):**
  - Recreate DB via `attendance_db.sql`, then POST `/admin_login.php` with default creds and confirm success.

### HP-003
- **Problem (what/where):** Admin CRUD endpoints are unauthenticated (`attendance_api/group_api.php`, `student_api.php`, `teacher_api.php`, `location_api.php`, `lessons_api.php`, reporting endpoints).
- **Why it matters:** Anyone with network access can create/delete data (data loss + privacy breach).
- **Proposed fix (exact approach):**
  - Issue an **admin JWT** on successful admin login.
  - Require `Authorization: Bearer <adminToken>` for admin endpoints (all write operations; optionally all reads).
  - Add an incremental “compat” mode (env toggle) if needed during migration to avoid breaking the app abruptly.
  - Update Flutter admin flow to store `admin_token` and attach it to admin requests.
- **Files involved (list):** `attendance_api/admin_login.php`, `attendance_api/*_api.php`, `attendance_api/lessons_api.php`, `flutter/lib/screens/login_page.dart`, `flutter/lib/screens/admin/*.dart`
- **Risk level:** High (touches auth + many endpoints)
- **Verification steps (how to confirm):**
  - Without token: admin endpoints return 401.
  - With token: CRUD works in Flutter admin UI.

### HP-004
- **Problem (what/where):** Attendance data can be overwritten from `present` to `absent`:
  - Flutter: `flutter/lib/screens/student/timetable.dart` auto-calls `mark_attendance.php` with `status='absent'`.
  - PHP: `attendance_api/mark_attendance.php` uses `ON DUPLICATE KEY UPDATE` allowing status changes.
- **Why it matters:** **Data loss/inaccurate records**; a legitimate “present” can become “absent” after the fact.
- **Proposed fix (exact approach):**
  - Backend: disallow changing an existing `present` record to `absent` (and optionally disallow changing `absent` to `present` outside a time window).
  - Client: only auto-mark absent when **no attendance row exists**; never send auto-absent if status is already present.
  - Add server-side validation for allowed transitions.
- **Files involved (list):** `attendance_api/mark_attendance.php`, `flutter/lib/screens/student/timetable.dart`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - Mark present, then trigger auto-absent logic: status remains present.
  - Mark absent when unmarked: status becomes absent.

### HP-005
- **Problem (what/where):** Server does not enforce key business rules for marking attendance:
  - No check that `lesson_id` belongs to the student’s `group_id`.
  - No check that `attendance_date` is within lesson start/end range or matches `day_of_week`.
  - No check that “present” is only allowed within the lesson time window.
- **Why it matters:** Students can mark attendance for wrong lessons/dates or outside class time.
- **Proposed fix (exact approach):**
  - In `mark_attendance.php`, load lesson by `lesson_id` and verify:
    - `lessons.group_id == token.group_id`
    - `attendance_date` within `[start_date, end_date]`
    - weekday matches `day_of_week`
    - for `present`, current time is within `[start_time, end_time]` and within allowed grace (configurable)
  - Validate `status` against a whitelist.
- **Files involved (list):** `attendance_api/mark_attendance.php`, `attendance_api/student_login.php` (ensure token has group_id), `attendance_db.sql`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - Try to mark present for another group’s lesson: denied.
  - Try to mark for wrong date: denied.
  - Mark present only during the class window: allowed.

### HP-006
- **Problem (what/where):** `attendance_api/get_subjects_by_group.php` appears to return a full session report payload (same as summary) while Flutter expects a simple subject list (`flutter/lib/screens/admin/attendance_report.dart`).
- **Why it matters:** Subject dropdown may break or be inconsistent; report filtering becomes unreliable.
- **Proposed fix (exact approach):**
  - Change `get_subjects_by_group.php` to return distinct subject names for a group (e.g. `SELECT DISTINCT subjects.name ...`).
  - Keep the current “summary” logic only in `get_attendance_summary.php`.
- **Files involved (list):** `attendance_api/get_subjects_by_group.php`, `flutter/lib/screens/admin/attendance_report.dart`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - Open admin report screen; subjects dropdown populates; filter works.

### HP-007
- **Problem (what/where):** Debug settings and error leakage:
  - `error_reporting(E_ALL)` + `display_errors=1` in some endpoints.
  - Some endpoints return raw PDO exception messages.
- **Why it matters:** Leaks internals and may reveal schema/paths/SQL to attackers.
- **Proposed fix (exact approach):**
  - Centralize error handling in `bootstrap.php` and disable display errors by default; optionally log to file.
  - Return consistent JSON error shapes with appropriate HTTP codes (400/401/403/500).
- **Files involved (list):** `attendance_api/group_api.php`, `attendance_api/location_api.php`, `attendance_api/*`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - Force a DB error; response is generic and does not leak SQL; server log captures details.

### HP-008
- **Problem (what/where):** Broken PDF export endpoint: `attendance_api/export_attendance_pdf.php` requires `tcpdf/tcpdf.php` which is not in the repo.
- **Why it matters:** Feature is broken and may confuse users; endpoint might throw fatal errors.
- **Proposed fix (exact approach):**
  - Either (A) add TCPDF via composer and update endpoint accordingly, or (B) deprecate it in docs and replace with the Flutter-side PDF export already implemented.
- **Files involved (list):** `attendance_api/export_attendance_pdf.php`, `attendance_api/composer.json`, `README.md`
- **Risk level:** Low/Medium (depending on approach)
- **Verification steps (how to confirm):**
  - If keeping: call endpoint and confirm PDF downloads.
  - If deprecating: README clearly states Flutter export is used.

---

## 2. Medium Priority (Maintainability / Architecture)

### MP-001
- **Problem (what/where):** Flutter has no API layer/models; HTTP logic duplicated across screens (`flutter/lib/screens/**/*.dart`).
- **Why it matters:** Changes to endpoints/auth/error handling are costly and bug-prone.
- **Proposed fix (exact approach):**
  - Add `flutter/lib/services/api_client.dart` with:
    - base URL from `api_config.dart`
    - standard headers + token injection
    - JSON parsing + typed errors
  - Introduce minimal typed models (e.g. `Lesson`, `AttendanceRecord`, `StudentProfile`) and migrate screen-by-screen.
- **Files involved (list):** `flutter/lib/services/*`, `flutter/lib/screens/*`, `flutter/lib/config/api_config.dart`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - `flutter analyze` passes; existing flows still work; fewer duplicated http blocks.

### MP-002
- **Problem (what/where):** Navigation + Drawer UI duplicated in many screens (Admin + Student).
- **Why it matters:** UI/route changes require many edits; inconsistent behavior (push vs pushReplacement).
- **Proposed fix (exact approach):**
  - Extract `AdminDrawer` and `StudentDrawer` widgets; unify navigation behavior.
- **Files involved (list):** `flutter/lib/screens/admin/*.dart`, `flutter/lib/screens/student/*.dart`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - Navigate between screens; back stack behaves consistently.

### MP-003
- **Problem (what/where):** Controllers not disposed in multiple StatefulWidgets.
- **Why it matters:** Memory leaks and warnings; harder to test.
- **Proposed fix (exact approach):** Add `dispose()` and call `controller.dispose()` where relevant.
- **Files involved (list):** `flutter/lib/screens/login_page.dart`, `flutter/lib/screens/admin/*.dart`, `flutter/lib/screens/student/profile_page.dart`
- **Risk level:** Low
- **Verification steps (how to confirm):** `flutter analyze` shows no controller leak lints/warnings.

### MP-004
- **Problem (what/where):** Permissions requested immediately on app start (`flutter/lib/main.dart`) without UX context; iOS `Info.plist` lacks location permission descriptions.
- **Why it matters:** Poor UX and iOS App Store rejection risk; denied permissions break core flows.
- **Proposed fix (exact approach):**
  - Request location permission when entering Timetable/attendance marking.
  - Request notification permission when enabling background reminders.
  - Add required `NSLocationWhenInUseUsageDescription` (and others as needed) in `flutter/ios/Runner/Info.plist`.
- **Files involved (list):** `flutter/lib/main.dart`, `flutter/lib/screens/student/timetable.dart`, `flutter/ios/Runner/Info.plist`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - iOS build runs and prompts with proper description strings; app handles denied states.

### MP-005
- **Problem (what/where):** Background task logs token substring and fetches all lessons (`flutter/lib/services/background_task.dart`).
- **Why it matters:** Token exposure in logs; unnecessary network/data usage.
- **Proposed fix (exact approach):**
  - Remove token logging; add server endpoint to fetch only the student group’s upcoming lessons.
  - Add retry/backoff and better failure handling.
- **Files involved (list):** `flutter/lib/services/background_task.dart`, `attendance_api/lessons_api.php` (or new endpoint)
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - Background task runs and triggers notifications with minimal payload; no token appears in logs.

### MP-006
- **Problem (what/where):** Timetable does N+1 network calls (`lessons_api.php` then `get_attendance_status.php` per lesson).
- **Why it matters:** Slow UI on real data; battery/network usage.
- **Proposed fix (exact approach):**
  - Add a JWT-protected endpoint returning timetable lessons for the selected date with embedded attendance status for that student.
- **Files involved (list):** `attendance_api/*`, `flutter/lib/screens/student/timetable.dart`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - One request loads timetable + statuses; UI performance improves.

### MP-007
- **Problem (what/where):** Reporting endpoints do repeated queries inside loops (`attendance_api/get_attendance_summary.php`).
- **Why it matters:** Can become slow as data grows.
- **Proposed fix (exact approach):**
  - Prefetch subject names once and bulk-load attendance rows for the date range to avoid per-date queries.
  - Add/verify indexes: `attendance(attendance_date, lesson_id)`, `lessons(group_id, day_of_week, start_date, end_date)`.
- **Files involved (list):** `attendance_api/get_attendance_summary.php`, `attendance_db.sql`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - Large group/date range query returns faster (compare before/after timings).

### MP-008
- **Problem (what/where):** Default Flutter test `flutter/test/widget_test.dart` does not match the actual app (no counter UI), so `flutter test` fails.
- **Why it matters:** Breaks CI and makes it hard to add confidence-building tests.
- **Proposed fix (exact approach):**
  - Replace with a widget test that asserts the Login UI renders and basic interactions work (e.g., shows “Login” and user type dropdown).
  - Add small unit tests for new shared utilities as they are introduced.
- **Files involved (list):** `flutter/test/widget_test.dart`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - Run `flutter test` and confirm it passes.

---

## 3. Low Priority (Nice-to-have / Polish)

### LP-001
- **Problem (what/where):** UI is functional but not cohesive; no global theme or design system.
- **Why it matters:** “Final year project” polish and user confidence.
- **Proposed fix (exact approach):** Add `ThemeData` (colors, typography), consistent spacing, and modern components; optionally add dark mode.
- **Files involved (list):** `flutter/lib/main.dart`, `flutter/lib/screens/**`
- **Risk level:** Low
- **Verification steps (how to confirm):** Visual review + no layout overflows.

### LP-002
- **Problem (what/where):** Mixed/garbled log/label characters (e.g., “??”) in Flutter source.
- **Why it matters:** Professionalism and readability.
- **Proposed fix (exact approach):** Replace with clear text and consistent logging.
- **Files involved (list):** `flutter/lib/services/background_task.dart`, `flutter/lib/main.dart`, `flutter/lib/screens/student/*`
- **Risk level:** Low
- **Verification steps (how to confirm):** Build runs; logs render correctly.

---

## 4. Dependency & Version Modernization
- **Flutter/Dart upgrades, package upgrades plan:**
  - Keep Flutter on stable (current machine: Flutter 3.35.7 / Dart 3.9.2).
  - Run `flutter pub upgrade` and commit lockfile updates (at minimum `shared_preferences` minor bump).
  - Remove unused deps (e.g. `dart_jsonwebtoken` if not used after audit).
- **PHP version target + library updates:**
  - Target PHP **8.2+** (current machine: PHP 8.4).
  - Update `firebase/php-jwt` to v7 after confirming API changes.
  - Add `vlucas/phpdotenv` for env loading.
- **MySQL schema/index improvements:**
  - Add/confirm composite indexes for report queries.
  - Stop shipping a “drop DB” script as the only migration strategy; introduce repeatable migrations (even a simple numbered SQL migrations folder).

---

## 5. Testing Strategy
- **Flutter unit/widget tests:**
  - Replace the default failing `flutter/test/widget_test.dart` with a test that matches the actual app (e.g. Login screen renders).
  - Add unit tests for `api_config.dart` and any new API client parsing.
- **PHP endpoint tests:**
  - Add lightweight PHPUnit tests for auth + attendance marking rules (or a minimal `tests/` folder with curl-based scripts if PHPUnit is too heavy).
  - Include token issuance + protected endpoint checks.
- **Test data / DB approach:**
  - Provide `attendance_db.sql` seed for dev.
  - Add a separate `attendance_db_test.sql` (or migration + seed runner) for automated tests.

---

## 6. CI/CD & Tooling
- **Lint/format:**
  - Flutter: `flutter analyze` + `dart format --set-exit-if-changed .`
  - PHP: `php -l` on all `attendance_api/*.php`; consider `PHP-CS-Fixer` + `PHPStan` once code is structured.
- **GitHub Actions pipeline suggestions:**
  - Job 1: Flutter analyze + test
  - Job 2: PHP lint + composer validate
- **Pre-commit hooks (optional):**
  - Run `dart format`, `flutter analyze`, `php -l`, and block committing secrets.

---

## 7. Implementation Order
1. **HP-001** Add backend env/config bootstrap and remove hardcoded secrets (keep local defaults).
2. **HP-007** Centralize error handling and remove `display_errors` + raw exception output.
3. **HP-006** Fix `get_subjects_by_group.php` to return a proper subject list (and adjust Flutter parsing if needed).
4. **HP-004** Prevent “present → absent” overwrites (server-side + client-side).
5. **HP-005** Add server-side attendance business rule validation (group/date/time window).
6. **MP-003** Dispose controllers and cleanup obvious Flutter leaks.
7. **MP-001** Introduce `ApiClient` and migrate 1–2 screens (Login + Student Profile) as the pattern.
8. **HP-002 + HP-003** Implement admin password hashing + admin JWT + protect admin endpoints; update Flutter admin to use token.
9. **MP-006** Add consolidated timetable endpoint to remove N+1 calls.
10. **Dependency modernization** Update dependencies safely and re-run checks.
11. **Tests/CI** Fix widget test, add basic endpoint tests, and add GitHub Actions.
