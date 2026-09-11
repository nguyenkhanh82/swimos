-- Migration: Add comprehensive swimmer profile fields
-- Adds weight, height, Swim USA ID, allergies, and unit preferences
-- to support nutrition tracking and personalized suggestions

-- Add new columns to swimmers table
ALTER TABLE public.swimmers
  ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS swim_usa_id TEXT,
  ADD COLUMN IF NOT EXISTS allergies TEXT,
  ADD COLUMN IF NOT EXISTS unit_preference TEXT CHECK (unit_preference IN ('imperial', 'metric')) DEFAULT 'metric';

-- Create index for Swim USA ID lookups
CREATE INDEX IF NOT EXISTS idx_swimmers_swim_usa_id 
ON public.swimmers(swim_usa_id) 
WHERE swim_usa_id IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.swimmers.weight_kg IS 'Weight in kilograms (stored in metric, displayed in user preference)';
COMMENT ON COLUMN public.swimmers.height_cm IS 'Height in centimeters (stored in metric, displayed in user preference)';
COMMENT ON COLUMN public.swimmers.swim_usa_id IS 'USA Swimming ID (separate from SwimCloud ID)';
COMMENT ON COLUMN public.swimmers.allergies IS 'Comma-separated list of allergies for nutrition tracking';
COMMENT ON COLUMN public.swimmers.unit_preference IS 'User preferred unit system: imperial (lbs, ft/in) or metric (kg, cm)';
