# Time Standards and Cuts Reference

The **Records page** shows time standards (B, BB, A, AA, AAA, AAAA) from the `time_standards` table, seeded in `supabase/migrations/20260118000201_seed_time_standards.sql`. **Motivational standards are driven by the swimmer’s age**: only standards for the swimmer’s age group (and gender, course) are shown — no fallback to other ages. This doc lists every standard and cut **currently in the app** and how to fix them with official data.

---

## Age-driven standards

Standards are **driven by the swimmer’s age**. The app maps current age to the DB `age_group` used in `time_standards`:

| Age (current) | age_group (DB)   |
|---------------|------------------|
| ≤ 10          | 10 & Under       |
| 11–12         | 11-12            |
| 13–14         | 13-14            |
| 15–16         | 15-16            |
| 17–18         | 17-18            |
| 19+           | Open             |

Only standards for that age group (and the swimmer’s gender and course) are shown on Records.

## Standard levels (order: slowest → fastest)

Motivational standards are **B through AAAA** only (not AAAAA).

| Level | Description |
|-------|-------------|
| **B**  | Slowest cut |
| **BB** | |
| **A**  | |
| **AA** | |
| **AAA** | |
| **AAAA** | Fastest motivational cut |

Times are in **seconds** (e.g. 28.99 = 28.99s). Display format: under 60s as "XX.XXs", 60+ as "M:SS.mm".

---

## All cuts currently in the app (from seed)

### Boys 13–14 (SCY)

| Event      | B      | BB     | A      | AA     | AAA    | AAAA   |
|------------|--------|--------|--------|--------|--------|--------|
| 50 Free    | 28.99  | 26.79  | 24.59  | 23.49  | 22.39  | 21.89  |
| 100 Free   | 63.99  | 58.99  | 53.99  | 51.49  | 48.99  | 47.99  |
| 200 Free   | 143.99 | 130.99 | 117.99 | 111.49 | 104.99 | 102.99 |
| 100 Back   | 72.99  | 66.99  | 60.99  | 57.99  | 54.99  | 53.99  |
| 100 Breast | 80.99  | 74.49  | 67.99  | 64.74  | 61.49  | 60.49  |
| 100 Fly    | 73.99  | 67.99  | 61.99  | 58.99  | 55.99  | 54.99  |
| 200 IM     | 156.99 | 143.99 | 130.99 | 124.49 | 117.99 | 115.99 |

### Girls 13–14 (SCY)

| Event      | B      | BB     | A      | AA     | AAA    | AAAA   |
|------------|--------|--------|--------|--------|--------|--------|
| 50 Free    | 30.99  | 28.59  | 26.19  | 24.99  | 23.79  | 23.29  |
| 100 Free   | 68.99  | 63.49  | 57.99  | 55.24  | 52.49  | 51.49  |

### Boys 15–16 (SCY)

| Event      | B      | BB     | A      | AA     | AAA    | AAAA   |
|------------|--------|--------|--------|--------|--------|--------|
| 50 Free    | 26.29  | 24.49  | 22.69  | 21.79  | 20.89  | 20.49  |
| 100 Free   | 57.99  | 53.99  | 49.99  | 47.99  | 45.99  | 45.19  |

### Open / Senior (SCY) – Boys

| Event      | B      | BB     | A      | AA     | AAA    | AAAA   |
|------------|--------|--------|--------|--------|--------|--------|
| 50 Free    | 25.29  | 23.59  | 21.89  | 21.09  | 20.29  | 19.89  |
| 100 Free   | 55.79  | 52.09  | 48.39  | 46.59  | 44.79  | 44.09  |

---

## Why it can look wrong

- The seed is a **representative sample**, not the full USA Swimming set. Many events/age groups are missing (e.g. Girls 13–14 only has 50 Free and 100 Free; no 200 Free, Back, Breast, Fly, IM for Girls 13–14 in the seed).
- The seed comment says "2024-2025 Season" but the **official USA Swimming 2024–2028 motivational times** use different cut times. For example, **Girls 13–14 SCY 50 Free**:  
  - **In app (seed):** B 30.99, A 26.19, AAAA 23.29  
  - **Official 2024–2028:** B 32.49, A 28.09, AAAA 24.19  
  So the app’s values are **not** the current USA Swimming motivational cuts.

---

## How to fix: use official USA Swimming cuts

1. **Official source**  
   USA Swimming publishes **2024–2028 National Age Group Motivational Time Standards** (updated Aug 2024, valid through 2028).  
   - PDF: [2024–2028 Motivational Standards (age group)](https://www.usaswimming.org/docs/default-source/timesdocuments/time-standards/2025/2028-motivational-standards-age-group.pdf) (or current link from usaswimming.org).  
   - Third-party reference: [NewSwimmer.com – USA Swimming Time Standards](https://www.newswimmer.com/usa-swimming-time-standards/), [SwimStandards.com](https://swimstandards.com/).

2. **Update the app**  
   - **Option A:** Replace or extend the seed in `supabase/migrations/20260118000201_seed_time_standards.sql` (or add a new migration) with official B–AAAA times for each event, gender, age group, and course (SCY/LCM).  
   - **Option B:** Add a sync job or script that pulls from an official source (e.g. USA Swimming PDF/API or a maintained CSV) and upserts into `time_standards`.  
   - The Records page reads from `time_standards`; no code change is needed once the table has the correct rows.

3. **Event name format**  
   The app uses event names like `50 Free`, `100 Back`, `200 IM`. The seed and any new data should use that same format so the Records page can match standards to swimmer times.

---

## Summary

| What you see on Records | Source |
|-------------------------|--------|
| Standard levels B → AAAAA | Same for everyone |
| Cut times per event       | `time_standards` table ← **seed file** (sample, not full/official) |
| Which standard a swimmer made | Compare swimmer’s best time to these cuts |

To have **correct** standards and cuts: replace or extend the seed (or sync from an official source) with **USA Swimming 2024–2028 motivational times (B–AAAA)** for all events, genders, age groups, and courses you support.
