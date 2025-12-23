# Fix & Improvement Plan

## 0. Quick Summary
- **What this project is:** A Flutter mobile attendance app with **Admin** and **Student** panels backed by a **vanilla PHP + MySQL** API. Students authenticate via **JWT**, can mark attendance using **geo-distance**, view timetable/history, and receive **background notifications** (WorkManager) if a class is about to start and they are far away.
- **Major remaining issues found:**
  - **Hygiene:** No CI, minimal tests, and no migration strategy beyond a "drop + recreate" SQL file.
- **Biggest remaining wins:**
  - Add CI + expand tests + introduce a migration strategy for DB changes.

---

## 1. High Priority (Security / Data Loss / Broken Builds)

No remaining High Priority items at the moment (previous HP items have been addressed and removed from this plan).

---

## 2. Medium Priority (Maintainability / Architecture)

No remaining Medium Priority items at the moment (previous MP items have been addressed and removed from this plan).

---

## 3. Low Priority (Nice-to-have / Polish)

No remaining Low Priority items at the moment (previous LP items have been addressed and removed from this plan).

---

## 4. Dependency & Version Modernization

### DM-001
- **Problem (what/where):** Flutter lockfile is behind latest allowed versions.
- **Why it matters:** Bugfix/security updates; fewer toolchain issues on newer Flutter stable.
- **Proposed fix (exact approach):** Run `flutter pub upgrade` (no major-constraint jumps) and commit `pubspec.lock`.
- **Files involved (list):** `flutter/pubspec.lock`
- **Risk level:** Low
- **Verification steps (how to confirm):** `flutter pub get`, `flutter analyze`, `flutter test`.

### DM-002
- **Problem (what/where):** Unused Flutter dependency (`dart_jsonwebtoken`) remains in `flutter/pubspec.yaml`.
- **Why it matters:** Extra transitive deps and slower builds; confusing for maintainers.
- **Proposed fix (exact approach):** Remove unused dependency after confirming it’s not imported anywhere.
- **Files involved (list):** `flutter/pubspec.yaml`, `flutter/pubspec.lock`
- **Risk level:** Low
- **Verification steps (how to confirm):** App compiles; `flutter analyze` + tests pass.

### DM-003
- **Problem (what/where):** Backend PHP version target isn’t explicitly documented/validated by Composer.
- **Why it matters:** Prevents subtle runtime incompatibilities; clearer dev environment expectations.
- **Proposed fix (exact approach):** Target PHP **8.2+** in `attendance_api/composer.json` and update README prerequisites.
- **Files involved (list):** `attendance_api/composer.json`, `README.md`
- **Risk level:** Low/Medium (depending on developer environments)
- **Verification steps (how to confirm):** `composer validate` passes; API runs under PHP 8.2+.

### DM-004
- **Problem (what/where):** `firebase/php-jwt` is pinned to v6 (`attendance_api/composer.json`).
- **Why it matters:** Staying current for security fixes and compatibility.
- **Proposed fix (exact approach):** Upgrade to v7 and update PHP code if API changes require it.
- **Files involved (list):** `attendance_api/composer.json`, `attendance_api/composer.lock`, `attendance_api/*.php`
- **Risk level:** Medium
- **Verification steps (how to confirm):** Admin/student login returns JWT; protected endpoints accept token; `php -l` and `composer validate`.

### DM-005
- **Problem (what/where):** Custom `.env` parser (`attendance_api/env.php`) is limited compared to standard parsers.
- **Why it matters:** Edge cases (quoted values, exported vars, whitespace) and maintainability.
- **Proposed fix (exact approach):** Add `vlucas/phpdotenv` and load it when available, keeping the custom loader as a fallback.
- **Files involved (list):** `attendance_api/composer.json`, `attendance_api/env.php`, `attendance_api/composer.lock`
- **Risk level:** Low
- **Verification steps (how to confirm):** `.env` values load correctly; DB connects; no behavior change when `.env` is absent.

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
