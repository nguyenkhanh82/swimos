-- Migration: Add swimcloud_id to team_members for easier SwimCloud API access
-- This allows fetching swimmer data directly from team_members without joining swimmers table

-- Add swimcloud_id column
ALTER TABLE public.team_members
  ADD COLUMN IF NOT EXISTS swimcloud_id TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_team_members_swimcloud_id ON public.team_members(swimcloud_id);

-- Populate existing rows with swimcloud_id from swimmers table
UPDATE public.team_members tm
SET swimcloud_id = s.swimcloud_id
FROM public.swimmers s
WHERE tm.swimmer_id = s.id
  AND tm.swimcloud_id IS NULL;

-- Create trigger function to automatically set swimcloud_id when inserting/updating
CREATE OR REPLACE FUNCTION public.set_team_member_swimcloud_id()
RETURNS TRIGGER AS $$
BEGIN
  -- If swimcloud_id is not provided, fetch it from swimmers table
  IF NEW.swimcloud_id IS NULL AND NEW.swimmer_id IS NOT NULL THEN
    SELECT swimcloud_id INTO NEW.swimcloud_id
    FROM public.swimmers
    WHERE id = NEW.swimmer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically populate swimcloud_id
DROP TRIGGER IF EXISTS trigger_set_team_member_swimcloud_id ON public.team_members;
CREATE TRIGGER trigger_set_team_member_swimcloud_id
  BEFORE INSERT OR UPDATE ON public.team_members
  FOR EACH ROW
  EXECUTE FUNCTION public.set_team_member_swimcloud_id();
