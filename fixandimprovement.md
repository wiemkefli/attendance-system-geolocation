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

### LP-004
- **Problem (what/where):** Planning/docs files are being edited locally but should not be re-committed.
- **Why it matters:** Avoids noisy diffs and accidental churn when iterating on notes.
- **Proposed fix (exact approach):** Add `fixandimprovement.md` and `CHANGELOG.md` to `.gitignore`.
- **Files involved (list):** `.gitignore`
- **Risk level:** Low
- **Verification steps (how to confirm):** `git status` stops showing changes after local edits (note: this only applies to untracked files).

---

## 4. Dependency & Version Modernization
- **Flutter/Dart upgrades, package upgrades plan:**
  - Keep Flutter on stable.
  - Run `flutter pub upgrade` and commit lockfile updates.
  - Evaluate major-version jumps via `flutter pub outdated` (do one-by-one with verification).
- **PHP version target + library updates:**
  - Target PHP **8.2+**.
  - Keep third-party libs current (review changelogs before major bumps).
  - Prefer standard env loading (Dotenv) while keeping local fallback behavior for dev.
- **MySQL schema/index improvements:**
  - Add/confirm composite indexes for report queries.
  - Stop shipping a "drop DB" script as the only migration strategy; introduce repeatable migrations (even a simple numbered SQL migrations folder).
- **Note:** Even on latest stable, some transitive packages may remain behind “Latest” due to Flutter SDK pinning; avoid `dependency_overrides` unless a specific issue forces it.

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
