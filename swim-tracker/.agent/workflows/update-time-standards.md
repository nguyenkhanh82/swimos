---
description: Update USA Swimming Time Standards (3-Month Cycle)
---

# Update Time Standards Workflow

This workflow describes how to update the time standards database from USA Swimming. This should be performed approximately every 3 months or when major standard changes are announced (e.g., new quadrennial defaults).

## 1. Verify Source URLs

Navigate to [USA Swimming Time Standards](https://www.usaswimming.org/times/time-standards) and confirm the URLs for the following standards. Update `scripts/inspect_pdf.ts` or `src/data/standards_seed.json` if these locations change.

**Current Links (as of Dec 2025):**
- **2024-2028 Motivational Times**: [Age Group PDF](https://websiteprodcoresa.blob.core.windows.net/sitefinity/docs/default-source/timesdocuments/time-standards/2025/2028-motivational-standards-age-group.pdf)
- **2025 Futures**: [Futures PDF](https://websiteprodcoresa.blob.core.windows.net/sitefinity/docs/default-source/timesdocuments/time-standards/2025/futures-championships-time-standards-2025.pdf)
- **2025 Junior Nationals**: [Summer Juniors PDF](https://websiteprodcoresa.blob.core.windows.net/sitefinity/docs/default-source/timesdocuments/time-standards/2025/speedo-junior-national-championships-time-standards-2025.pdf)
- **2026 Sectionals**: [Sectionals PDF](https://websiteprodcoresa.blob.core.windows.net/sitefinity/docs/default-source/timesdocuments/time-standards/2026/2026_speedosectionals_timestandards_max.pdf)

## 2. Prepare the Data

If the URLs have new content:
1.  **Extract Data**: Since the data is in PDF format, manual extraction or a specialized PDF parsing tool is required to convert the tables into JSON format matching `src/data/standards_seed.json`.
    - **Schema**:
      ```json
      {
        "gender": "M" | "F",
        "age_group": "11-12",
        "event_name": "50 Free",
        "course": "SCY" | "LCM",
        "standards": {
          "AAAA": 24.09,
          "AAA": 25.19,
           ...
        }
      }
      ```
2.  **Update Seed File**: Paste the new JSON data into `src/data/standards_seed.json`.

## 3. Update the Database

### Motivational standards (all age groups: 10 & Under, 11-12, 13-14, 15-16, 17-18)

The app reads motivational time standards (B–AAAA) from the `time_standards` table. To populate **all age groups and events** from `time_standard.json`:

**Option A – Python script (recommended)**  
From repo root, with Supabase credentials set:

```bash
export SUPABASE_URL=https://YOUR_PROJECT.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
pip install supabase
python3 scripts/sync_time_standards_to_db.py
```

**Option B – Run the migration SQL**  
1. Generate the migration: `python3 scripts/generate_time_standards_migration.py`  
2. In Supabase Dashboard → SQL Editor, run the new migration file (e.g. `supabase/migrations/YYYYMMDD_sync_time_standards_from_json.sql`).  
   If the file is too large, run it in chunks: execute each `INSERT INTO public.time_standards ... VALUES ... ;` block separately (skip the `DELETE` if you only want to add/replace motivational rows and keep national tiers).

**Option C – Supabase CLI**  
If the project is linked:  
`supabase db execute --file supabase/migrations/20260205220739_sync_time_standards_from_json.sql`  
(Note: this migration does `DELETE FROM time_standards` then inserts only motivational data; re-run the national-tier migration afterward if you need Sectional/Futures/Junior National/National back.)

### Legacy seeding (if used)

```bash
# Ensure your .env has VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY (or SERVICE_KEY for writes if RLS requires it)
npx tsx scripts/seed_standards.ts
```

## 4. Verify in Application

Open the "Meets" page in the application and verify that the "Next Level Standards" progress bars reflect the new times.

## 5. Notes

- The system currently falls back to `src/data/standards_seed.json` if the database table is empty or unreachable.
- To handle large updates, consider automating the PDF scraping with a dedicated Python script (using `tabula-py` or similar) which works better for PDF tables than Node.js libraries.
