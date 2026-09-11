-- Migration: Migrate data from old time standards tables to unified structure
-- Created: 2026-01-26
-- Purpose: Consolidate all existing time standards data into unified_time_standards

-- Helper function to normalize event names
-- Converts "50 Free" -> "50 FR", "100 Back" -> "100 BK", etc.
CREATE OR REPLACE FUNCTION normalize_event_name(event_name TEXT, stroke_name TEXT, distance_val INTEGER)
RETURNS TEXT AS $$
DECLARE
  stroke_abbrev TEXT;
BEGIN
  -- Map stroke to abbreviation
  CASE stroke_name
    WHEN 'Free' THEN stroke_abbrev := 'FR';
    WHEN 'Back' THEN stroke_abbrev := 'BK';
    WHEN 'Breast' THEN stroke_abbrev := 'BR';
    WHEN 'Fly' THEN stroke_abbrev := 'FL';
    WHEN 'IM' THEN stroke_abbrev := 'IM';
    ELSE stroke_abbrev := UPPER(SUBSTRING(stroke_name, 1, 2));
  END CASE;
  
  -- Handle special cases
  IF event_name LIKE '%/500%' OR event_name LIKE '%/400%' THEN
    RETURN event_name; -- Keep as is for combined events
  END IF;
  
  -- Return normalized format: "50 FR", "100 BK", etc.
  RETURN distance_val || ' ' || stroke_abbrev;
END;
$$ LANGUAGE plpgsql;

-- Step 1: Migrate data from old time_standards table (motivational times)
-- Aggregate course-based structure to combine SCY/LCM/SCM into single rows
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  normalize_event_name(MAX(ts.event), MAX(ts.stroke), MAX(ts.distance)) as event,
  CASE MAX(ts.gender)
    WHEN 'M' THEN 'MEN'
    WHEN 'F' THEN 'WOMEN'
    ELSE MAX(ts.gender)
  END as gender,
  MAX(ts.age_group) as age_group,
  MAX(CASE WHEN ts.course = 'SCY' THEN 
    CASE 
      WHEN ts.time_seconds < 60 THEN ts.time_seconds::TEXT
      ELSE FLOOR(ts.time_seconds / 60)::TEXT || ':' || LPAD((ts.time_seconds % 60)::TEXT, 5, '0')
    END
  END) as scy_time,
  MAX(CASE WHEN ts.course = 'LCM' THEN 
    CASE 
      WHEN ts.time_seconds < 60 THEN ts.time_seconds::TEXT
      ELSE FLOOR(ts.time_seconds / 60)::TEXT || ':' || LPAD((ts.time_seconds % 60)::TEXT, 5, '0')
    END
  END) as lcm_time,
  MAX(CASE WHEN ts.course = 'SCM' THEN 
    CASE 
      WHEN ts.time_seconds < 60 THEN ts.time_seconds::TEXT
      ELSE FLOOR(ts.time_seconds / 60)::TEXT || ':' || LPAD((ts.time_seconds % 60)::TEXT, 5, '0')
    END
  END) as scm_time,
  MAX(CASE WHEN ts.course = 'SCY' THEN ts.time_seconds END) as scy_seconds,
  MAX(CASE WHEN ts.course = 'LCM' THEN ts.time_seconds END) as lcm_seconds,
  MAX(CASE WHEN ts.course = 'SCM' THEN ts.time_seconds END) as scm_seconds,
  COALESCE(EXTRACT(YEAR FROM MAX(ts.effective_date))::INTEGER, 2026) as year,
  MAX(tst.id) as standard_id
FROM public.time_standards ts
JOIN time_standard_types tst ON tst.competition = 'MOTIVATIONAL' AND tst.standard_type = ts.standard_level
GROUP BY 
  normalize_event_name(ts.event, ts.stroke, ts.distance),
  CASE ts.gender WHEN 'M' THEN 'MEN' WHEN 'F' THEN 'WOMEN' ELSE ts.gender END,
  ts.age_group,
  tst.id,
  COALESCE(EXTRACT(YEAR FROM ts.effective_date)::INTEGER, 2026)
ON CONFLICT DO NOTHING;

-- Step 2: Migrate data from usa_swimming_qualifying_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  usq.event,
  usq.gender,
  NULL as age_group, -- USA Qualifying doesn't have age_group
  usq.scy_time,
  usq.lcm_time,
  NULL as scm_time,
  usq.scy_seconds,
  usq.lcm_seconds,
  NULL as scm_seconds,
  usq.year,
  tst.id as standard_id
FROM usa_swimming_qualifying_standards usq
JOIN time_standard_types tst ON tst.competition = 'USA_QUALIFYING' AND tst.standard_type = usq.standard_type
ON CONFLICT DO NOTHING;

-- Step 3: Migrate data from sectionals_time_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  sts.event,
  sts.gender,
  NULL as age_group, -- Sectionals doesn't have age_group
  sts.scy_time,
  sts.lcm_time,
  NULL as scm_time,
  sts.scy_seconds,
  sts.lcm_seconds,
  NULL as scm_seconds,
  sts.year,
  tst.id as standard_id
FROM sectionals_time_standards sts
JOIN time_standard_types tst ON tst.competition = 'SPEEDO_SECTIONALS' AND tst.standard_type IS NULL
ON CONFLICT DO NOTHING;

-- Step 4: Migrate data from futures_time_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  fts.event,
  fts.gender,
  fts.age_group, -- Futures has age_group
  fts.scy_time,
  fts.lcm_time,
  NULL as scm_time,
  fts.scy_seconds,
  fts.lcm_seconds,
  NULL as scm_seconds,
  fts.year,
  tst.id as standard_id
FROM futures_time_standards fts
JOIN time_standard_types tst ON tst.competition = 'FUTURES_CHAMPIONSHIPS' AND tst.standard_type IS NULL
ON CONFLICT DO NOTHING;

-- Step 5: Migrate data from winter_junior_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  wjs.event,
  wjs.gender,
  NULL as age_group, -- Winter Junior doesn't have age_group
  wjs.scy_time,
  wjs.lcm_time,
  NULL as scm_time,
  wjs.scy_seconds,
  wjs.lcm_seconds,
  NULL as scm_seconds,
  wjs.year,
  tst.id as standard_id
FROM winter_junior_standards wjs
JOIN time_standard_types tst ON tst.competition = 'WINTER_JUNIOR_CHAMPIONSHIPS' AND tst.standard_type = wjs.standard_type
ON CONFLICT DO NOTHING;

-- Step 6: Migrate data from toyota_nationals_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  tns.event,
  tns.gender,
  tns.age_group, -- Toyota Nationals has age_group
  tns.scy_time,
  tns.lcm_time,
  NULL as scm_time,
  tns.scy_seconds,
  tns.lcm_seconds,
  NULL as scm_seconds,
  tns.year,
  tst.id as standard_id
FROM toyota_nationals_standards tns
JOIN time_standard_types tst ON tst.competition = 'TOYOTA_NATIONALS' AND tst.standard_type IS NULL
ON CONFLICT DO NOTHING;

-- Step 7: Migrate data from usa_nationals_standards
INSERT INTO unified_time_standards (
  event, gender, age_group, scy_time, lcm_time, scm_time,
  scy_seconds, lcm_seconds, scm_seconds, year, standard_id
)
SELECT
  uns.event,
  uns.gender,
  uns.age_group, -- USA Nationals has age_group
  uns.scy_time,
  uns.lcm_time,
  NULL as scm_time,
  uns.scy_seconds,
  uns.lcm_seconds,
  NULL as scm_seconds,
  uns.year,
  tst.id as standard_id
FROM usa_nationals_standards uns
JOIN time_standard_types tst ON tst.competition = 'USA_NATIONALS' AND tst.standard_type IS NULL
ON CONFLICT DO NOTHING;

-- Clean up helper function
DROP FUNCTION IF EXISTS normalize_event_name(TEXT, TEXT, INTEGER);
