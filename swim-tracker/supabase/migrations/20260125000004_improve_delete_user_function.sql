-- Improve delete_user function to ensure complete user deletion
-- Note: This function deletes from auth.users, but Supabase Auth may still
-- prevent email reuse for security reasons. For complete deletion, use Supabase Dashboard
-- or wait a few minutes after deletion.

CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_to_delete UUID;
BEGIN
  -- Get the current user's ID
  user_id_to_delete := auth.uid();
  
  IF user_id_to_delete IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to delete account';
  END IF;

  -- Delete from auth.users (this will cascade to profiles and other tables)
  -- Note: This requires proper permissions. If it fails, user must delete via Supabase Dashboard
  DELETE FROM auth.users WHERE id = user_id_to_delete;
  
  -- The ON DELETE CASCADE constraints will automatically delete:
  -- - public.profiles
  -- - public.swimmers
  -- - public.teams (where created_by = user_id)
  -- - public.team_members
  -- - public.training_goals
  -- - public.goal_progress_entries
  -- - public.oauth_tokens
  -- - And all other related data
  
END;
$$;

COMMENT ON FUNCTION public.delete_user() IS 
'Deletes the current authenticated user from auth.users. 
Note: Supabase Auth may prevent immediate email reuse for security reasons. 
For complete deletion, use Supabase Dashboard Auth section.';
