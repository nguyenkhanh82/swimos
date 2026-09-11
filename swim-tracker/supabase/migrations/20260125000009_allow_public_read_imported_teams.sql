-- Allow public read access to teams imported from SwimCloud
-- This enables team search functionality for users to find and join existing teams
CREATE POLICY "Users can view imported teams (for search)" ON public.teams
  FOR SELECT USING (
    team_type = 'regular' AND
    is_active = true
  );
