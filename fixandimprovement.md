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
1. **Dependency modernization** Upgrade deps safely and re-run checks.
2. **Tests/CI** Expand tests and add GitHub Actions.
3. **LP items** Theme polish + text cleanup.
