-- Extend time_standards to support national-level standards and additional age groups.
-- National data is loaded from national_time_standard.json (Sectional, Futures, Junior National, National).

-- 1. Extend standard_level to include national tiers
ALTER TABLE public.time_standards
  DROP CONSTRAINT IF EXISTS time_standards_standard_level_check;

ALTER TABLE public.time_standards
  ADD CONSTRAINT time_standards_standard_level_check
  CHECK (standard_level IN (
    'B', 'BB', 'A', 'AA', 'AAA', 'AAAA',
    'Sectional', 'Futures', 'Futures Bonus', 'Junior National', 'Junior National Bonus', 'National'
  ));

COMMENT ON COLUMN public.time_standards.standard_level IS 'Motivational: B, BB, A, AA, AAA, AAAA. National: Sectional, Futures, Futures Bonus, Junior National, Junior National Bonus, National';

-- 2. Extend age_group to include national meet age groups
ALTER TABLE public.time_standards
  DROP CONSTRAINT IF EXISTS time_standards_age_group_check;

ALTER TABLE public.time_standards
  ADD CONSTRAINT time_standards_age_group_check
  CHECK (age_group IN (
    '10 & Under', '11-12', '13-14', '15-16', '17-18', 'Open',
    '18 & Under', '19 & Over', 'All Age'
  ));

COMMENT ON COLUMN public.time_standards.age_group IS 'USA Swimming age groups; national meets use 18 & Under, 19 & Over, All Age';

-- 3. Drop unique constraint so we can have same (gender, age_group, course, event) with different standard_level
-- Existing: UNIQUE(gender, age_group, course, event, standard_level) - that already allows multiple standard_levels per event.
-- So we keep it. No change needed.
