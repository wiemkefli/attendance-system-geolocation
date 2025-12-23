# Fix & Improvement Plan

## 0. Quick Summary
- **What this project is:** A Flutter mobile attendance app with **Admin** and **Student** panels backed by a **vanilla PHP + MySQL** API. Students authenticate via **JWT**, can mark attendance using **geo-distance**, view timetable/history, and receive **background notifications** (WorkManager) if a class is about to start and they are far away.
- **Major remaining issues found:**
  - **Broken backend feature:** `attendance_api/export_attendance_pdf.php` references `tcpdf/` which is not present.
  - **Maintainability:** Lots of duplicated Flutter UI/navigation and a mostly “screen-by-screen HTTP” approach still exists.
  - **Performance:** Timetable still does N+1 network calls and lessons are fetched broadly.
  - **Hygiene:** No CI, minimal tests, and no migration strategy beyond a “drop + recreate” SQL file.
- **Biggest remaining wins:**
  - Decide what to do with server-side PDF export (fix or deprecate).
  - Consolidate timetable endpoint to remove N+1 calls.
  - Add CI + expand tests + introduce a migration strategy for DB changes.

---

## 1. High Priority (Security / Data Loss / Broken Builds)

### HP-008
- **Problem (what/where):** Broken PDF export endpoint: `attendance_api/export_attendance_pdf.php` requires `tcpdf/tcpdf.php` which is not in the repo.
- **Why it matters:** Feature is broken and may confuse users; endpoint might throw fatal errors.
- **Proposed fix (exact approach):**
  - Either (A) add TCPDF via composer and update endpoint accordingly, or (B) deprecate/remove the endpoint from docs and rely on the Flutter-side PDF export already implemented.
- **Files involved (list):** `attendance_api/export_attendance_pdf.php`, `attendance_api/composer.json`, `README.md`
- **Risk level:** Low/Medium (depending on approach)
- **Verification steps (how to confirm):**
  - If keeping: call endpoint and confirm PDF downloads.
  - If deprecating: README clearly states Flutter export is used.

---

## 2. Medium Priority (Maintainability / Architecture)

### MP-002
- **Problem (what/where):** Navigation + Drawer UI duplicated in many screens (Admin + Student).
- **Why it matters:** UI/route changes require many edits; inconsistent behavior (push vs pushReplacement).
- **Proposed fix (exact approach):**
  - Extract `AdminDrawer` and `StudentDrawer` widgets; unify navigation behavior.
- **Files involved (list):** `flutter/lib/screens/admin/*.dart`, `flutter/lib/screens/student/*.dart`
- **Risk level:** Low
- **Verification steps (how to confirm):**
  - Navigate between screens; back stack behaves consistently.

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
- **Problem (what/where):** Background task logs sensitive-ish data and fetches broad lesson lists (`flutter/lib/services/background_task.dart`).
- **Why it matters:** Token exposure risk in logs; unnecessary network/data usage.
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

### MP-009
- **Problem (what/where):** Flutter still has a lot of direct HTTP + dynamic map parsing across screens (inconsistent error handling and duplicated logic).
- **Why it matters:** Changes to endpoints/auth/error handling remain costly and bug-prone.
- **Proposed fix (exact approach):**
  - Continue migrating screens to a shared API layer and introduce typed models incrementally (start with timetable + admin CRUD).
- **Files involved (list):** `flutter/lib/screens/**`, `flutter/lib/services/**`
- **Risk level:** Medium
- **Verification steps (how to confirm):**
  - `flutter analyze` passes; fewer duplicated http blocks; consistent error UI.

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
  - Keep Flutter on stable.
  - Run `flutter pub upgrade` and commit lockfile updates.
  - Remove unused deps (e.g. `dart_jsonwebtoken` if it stays unused).
- **PHP version target + library updates:**
  - Target PHP **8.2+**.
  - Update `firebase/php-jwt` to v7 after confirming API changes.
  - Consider using a standard env loader (`vlucas/phpdotenv`) instead of a custom one.
- **MySQL schema/index improvements:**
  - Add/confirm composite indexes for report queries.
  - Stop shipping a “drop DB” script as the only migration strategy; introduce repeatable migrations (even a simple numbered SQL migrations folder).

---

## 5. Testing Strategy
- **Flutter unit/widget tests:**
  - Add widget tests for student/admin navigation flows.
  - Add unit tests for new API parsing/models as they are introduced.
- **PHP endpoint tests:**
  - Add PHPUnit tests for auth + attendance marking rules (or a minimal `tests/` folder with curl-based scripts if PHPUnit is too heavy).
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
1. **HP-008** Decide: fix or deprecate `export_attendance_pdf.php`.
2. **MP-006** Add consolidated timetable endpoint to remove N+1 calls.
3. **MP-005** Reduce background task logging + payload.
4. **MP-002** Extract shared drawers and unify navigation.
5. **MP-009** Continue API layer + models migration incrementally.
6. **MP-007** Optimize reporting queries and add indexes.
7. **Dependency modernization** Upgrade deps safely and re-run checks.
8. **Tests/CI** Expand tests and add GitHub Actions.
