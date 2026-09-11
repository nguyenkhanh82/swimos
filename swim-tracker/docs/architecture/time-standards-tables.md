# Time Standards Tables: Relationship and Usage

The project uses a **single** time-standards table in the database.

---

## `time_standards` (used by the app)

**Purpose:** USA Swimming time standards: **motivational** (B, BB, A, AA, AAA, AAAA) and **national-level** (Sectional, Futures, Futures Bonus, Junior National, Junior National Bonus, National) by age group, gender, and course.

**Schema:**
- `id`, `gender`, `age_group`, `course`, `event`, `stroke`, `distance`, `standard_level`, `time_seconds`, `effective_date`
- One row per cut: e.g. (F, 13-14, SCY, 50 Free, Free, 50, AAAA, 24.39) or (M, 18 & Under, LCM, 100 Free, Free, 100, National, 51.99)

**Used by:**
- **Records screen** – via `TimeStandardsRepository` (and fallback when asset loader is used first)
- **Meet details** – time standards bar for an event
- **Goal suggestions** – next standard to aim for
- **Time standards service** – current/next standard for a swimmer

**Source of truth:**
- Motivational (B–AAAA): synced from `time_standard.json` by the migration generated with `scripts/generate_time_standards_migration.py`.
- National tiers: synced from `national_time_standard.json` by `scripts/generate_national_time_standards_migration.py` (migration `sync_national_time_standards`).

**Relationship:** Standalone. No foreign keys to other tables.

---

## Summary

| Table              | Role                                                         | Used by app? |
|--------------------|--------------------------------------------------------------|--------------|
| **time_standards** | Motivational (B–AAAA) + national (Sectional, Futures, …)    | **Yes**      |

- **App usage:** Only **`time_standards`** is used (Records, meet bar, goal suggestions, time standards service).
- **Data:** Motivational from **`time_standard.json`**; national from **`national_time_standard.json`**.
