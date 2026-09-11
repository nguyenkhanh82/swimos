-- Migration: Remove user_id requirement from team_members
-- Now that we've migrated to swimmer_id, we can make user_id nullable
-- and make swimmer_id required

-- First, make user_id nullable (for existing data)
ALTER TABLE public.team_members
  ALTER COLUMN user_id DROP NOT NULL;

-- Make swimmer_id required (NOT NULL)
ALTER TABLE public.team_members
  ALTER COLUMN swimmer_id SET NOT NULL;

-- Drop the old unique constraint on user_id if it still exists
ALTER TABLE public.team_members
  DROP CONSTRAINT IF EXISTS unique_user_team;

-- The unique_swimmer_team constraint should already exist from the previous migration
-- But ensure it's there
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_swimmer_team'
  ) THEN
    ALTER TABLE public.team_members
      ADD CONSTRAINT unique_swimmer_team UNIQUE (swimmer_id, team_id);
  END IF;
END $$;

-- Update any existing rows that might have NULL swimmer_id
-- (This shouldn't happen, but just in case)
UPDATE public.team_members tm
SET swimmer_id = (
  SELECT s.id 
  FROM public.swimmers s 
  WHERE s.user_id = tm.user_id 
    AND s.is_primary = true 
  LIMIT 1
)
WHERE tm.swimmer_id IS NULL
  AND tm.user_id IS NOT NULL;

-- Note: We keep user_id column for now (nullable) in case we need it for queries
-- But it's no longer required for inserts
