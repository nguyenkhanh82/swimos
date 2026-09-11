-- Drop unused tables: app uses time_standards only.
-- unified_time_standards references time_standard_types, so drop child first.
DROP TABLE IF EXISTS public.unified_time_standards;
DROP TABLE IF EXISTS public.time_standard_types;
