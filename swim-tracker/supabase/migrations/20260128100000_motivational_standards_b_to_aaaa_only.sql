-- Motivational time standards are B through AAAA only (not AAAAA).
-- Remove AAAAA rows and restrict standard_level to B, BB, A, AA, AAA, AAAA.

-- 1. Delete any existing AAAAA rows from time_standards
DELETE FROM public.time_standards
WHERE standard_level = 'AAAAA';

-- 2. Drop the existing check constraint on standard_level (name from create_time_standards)
ALTER TABLE public.time_standards
  DROP CONSTRAINT IF EXISTS time_standards_standard_level_check;

-- 3. Add new check constraint: motivational levels B through AAAA only
ALTER TABLE public.time_standards
  ADD CONSTRAINT time_standards_standard_level_check
  CHECK (standard_level IN ('B', 'BB', 'A', 'AA', 'AAA', 'AAAA'));

-- 4. Update column comment
COMMENT ON COLUMN public.time_standards.standard_level IS 'B, BB, A, AA, AAA, AAAA motivational time standards (not AAAAA)';
