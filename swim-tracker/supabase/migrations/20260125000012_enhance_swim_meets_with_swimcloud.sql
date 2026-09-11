-- Migration: Enhance swim_meets table with SwimCloud integration fields
-- Adds fields to link meets with SwimCloud data and provide additional metadata

-- Add SwimCloud integration fields
ALTER TABLE public.swim_meets
  ADD COLUMN IF NOT EXISTS swimcloud_meet_id TEXT,
  ADD COLUMN IF NOT EXISTS meet_type TEXT,
  ADD COLUMN IF NOT EXISTS organization TEXT,
  ADD COLUMN IF NOT EXISTS swimcloud_url TEXT;

-- Create index for SwimCloud meet ID lookups
CREATE INDEX IF NOT EXISTS idx_swim_meets_swimcloud_id ON public.swim_meets(swimcloud_meet_id);

-- Add comment for documentation
COMMENT ON COLUMN public.swim_meets.swimcloud_meet_id IS 'SwimCloud meet ID for linking with external data';
COMMENT ON COLUMN public.swim_meets.meet_type IS 'Type of meet: Championship, Invitational, Dual Meet, etc.';
COMMENT ON COLUMN public.swim_meets.organization IS 'Meet organizer or organization name';
COMMENT ON COLUMN public.swim_meets.swimcloud_url IS 'Link to SwimCloud meet page';
