-- Remove Futures Bonus: Futures time standards use only 18 & Under and 19 & Over (no bonus tier).
-- 1. Delete all time_standards rows for Futures Bonus
DELETE FROM public.time_standards
WHERE standard_level = 'Futures Bonus';

-- 2. Update check constraint to drop Futures Bonus from allowed standard_level values
ALTER TABLE public.time_standards
  DROP CONSTRAINT IF EXISTS time_standards_standard_level_check;

ALTER TABLE public.time_standards
  ADD CONSTRAINT time_standards_standard_level_check
  CHECK (standard_level IN (
    'B', 'BB', 'A', 'AA', 'AAA', 'AAAA',
    'Sectional', 'Futures', 'Junior National', 'Junior National Bonus', 'National'
  ));

COMMENT ON COLUMN public.time_standards.standard_level IS 'Motivational: B, BB, A, AA, AAA, AAAA. National: Sectional, Futures, Junior National, Junior National Bonus, National';
