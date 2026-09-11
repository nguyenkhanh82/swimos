-- Migration: Update RLS Policies for Multi-Swimmer Support
-- Updates all RLS policies to check swimmer ownership via user_id

-- Helper function to check swimmer ownership
CREATE OR REPLACE FUNCTION public.user_owns_swimmer(swimmer_id_param UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.swimmers s 
    WHERE s.id = swimmer_id_param 
    AND s.user_id = auth.uid()
  );
$$;

-- ============================================================================
-- Training Sets RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own training sets" ON public.training_sets;
DROP POLICY IF EXISTS "Users can create their own training sets" ON public.training_sets;
DROP POLICY IF EXISTS "Users can update their own training sets" ON public.training_sets;
DROP POLICY IF EXISTS "Users can delete their own training sets" ON public.training_sets;

CREATE POLICY "Users can view their swimmers' training sets"
ON public.training_sets FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create training sets for their swimmers"
ON public.training_sets FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' training sets"
ON public.training_sets FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' training sets"
ON public.training_sets FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Training Set Splits RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own splits" ON public.training_set_splits;
DROP POLICY IF EXISTS "Users can create their own splits" ON public.training_set_splits;
DROP POLICY IF EXISTS "Users can update their own splits" ON public.training_set_splits;
DROP POLICY IF EXISTS "Users can delete their own splits" ON public.training_set_splits;

CREATE POLICY "Users can view their swimmers' splits"
ON public.training_set_splits FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create splits for their swimmers"
ON public.training_set_splits FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' splits"
ON public.training_set_splits FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' splits"
ON public.training_set_splits FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Swim Meets RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own swim meets" ON public.swim_meets;
DROP POLICY IF EXISTS "Users can create their own swim meets" ON public.swim_meets;
DROP POLICY IF EXISTS "Users can update their own swim meets" ON public.swim_meets;
DROP POLICY IF EXISTS "Users can delete their own swim meets" ON public.swim_meets;

CREATE POLICY "Users can view their swimmers' meets"
ON public.swim_meets FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create meets for their swimmers"
ON public.swim_meets FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' meets"
ON public.swim_meets FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' meets"
ON public.swim_meets FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Meet Entries RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own meet entries" ON public.meet_entries;
DROP POLICY IF EXISTS "Users can create their own meet entries" ON public.meet_entries;
DROP POLICY IF EXISTS "Users can update their own meet entries" ON public.meet_entries;
DROP POLICY IF EXISTS "Users can delete their own meet entries" ON public.meet_entries;

CREATE POLICY "Users can view their swimmers' meet entries"
ON public.meet_entries FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create meet entries for their swimmers"
ON public.meet_entries FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' meet entries"
ON public.meet_entries FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' meet entries"
ON public.meet_entries FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Training Goals RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own goals" ON public.training_goals;
DROP POLICY IF EXISTS "Users can create their own goals" ON public.training_goals;
DROP POLICY IF EXISTS "Users can update their own goals" ON public.training_goals;
DROP POLICY IF EXISTS "Users can delete their own goals" ON public.training_goals;

CREATE POLICY "Users can view their swimmers' goals"
ON public.training_goals FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create goals for their swimmers"
ON public.training_goals FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' goals"
ON public.training_goals FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' goals"
ON public.training_goals FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Goal Progress Entries RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own progress entries" ON public.goal_progress_entries;
DROP POLICY IF EXISTS "Users can create their own progress entries" ON public.goal_progress_entries;
DROP POLICY IF EXISTS "Users can update their own progress entries" ON public.goal_progress_entries;
DROP POLICY IF EXISTS "Users can delete their own progress entries" ON public.goal_progress_entries;

CREATE POLICY "Users can view their swimmers' progress entries"
ON public.goal_progress_entries FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create progress entries for their swimmers"
ON public.goal_progress_entries FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' progress entries"
ON public.goal_progress_entries FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' progress entries"
ON public.goal_progress_entries FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Goal Milestones RLS Policies
-- ============================================================================
-- Note: Milestones are linked via goal_id, but we check swimmer_id for direct access
CREATE POLICY "Users can view their swimmers' milestones"
ON public.goal_milestones FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create milestones for their swimmers"
ON public.goal_milestones FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' milestones"
ON public.goal_milestones FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' milestones"
ON public.goal_milestones FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Nutrition Logs RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own nutrition logs" ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can create their own nutrition logs" ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can update their own nutrition logs" ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can delete their own nutrition logs" ON public.nutrition_logs;

CREATE POLICY "Users can view their swimmers' nutrition logs"
ON public.nutrition_logs FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create nutrition logs for their swimmers"
ON public.nutrition_logs FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' nutrition logs"
ON public.nutrition_logs FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' nutrition logs"
ON public.nutrition_logs FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Nutrition Goals RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own nutrition goals" ON public.nutrition_goals;
DROP POLICY IF EXISTS "Users can create their own nutrition goals" ON public.nutrition_goals;
DROP POLICY IF EXISTS "Users can update their own nutrition goals" ON public.nutrition_goals;
DROP POLICY IF EXISTS "Users can delete their own nutrition goals" ON public.nutrition_goals;

CREATE POLICY "Users can view their swimmers' nutrition goals"
ON public.nutrition_goals FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create nutrition goals for their swimmers"
ON public.nutrition_goals FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' nutrition goals"
ON public.nutrition_goals FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' nutrition goals"
ON public.nutrition_goals FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Meal Plans RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can create their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can update their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can delete their own meal plans" ON public.meal_plans;

CREATE POLICY "Users can view their swimmers' meal plans"
ON public.meal_plans FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create meal plans for their swimmers"
ON public.meal_plans FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' meal plans"
ON public.meal_plans FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' meal plans"
ON public.meal_plans FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Nutrition Daily Tracking RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own tracking records" ON public.nutrition_daily_tracking;
DROP POLICY IF EXISTS "Users can create their own tracking records" ON public.nutrition_daily_tracking;
DROP POLICY IF EXISTS "Users can update their own tracking records" ON public.nutrition_daily_tracking;
DROP POLICY IF EXISTS "Users can delete their own tracking records" ON public.nutrition_daily_tracking;

CREATE POLICY "Users can view their swimmers' daily tracking"
ON public.nutrition_daily_tracking FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create daily tracking for their swimmers"
ON public.nutrition_daily_tracking FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' daily tracking"
ON public.nutrition_daily_tracking FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' daily tracking"
ON public.nutrition_daily_tracking FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Custom Tracked Events RLS Policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own custom events" ON public.custom_tracked_events;
DROP POLICY IF EXISTS "Users can create their own custom events" ON public.custom_tracked_events;
DROP POLICY IF EXISTS "Users can update their own custom events" ON public.custom_tracked_events;
DROP POLICY IF EXISTS "Users can delete their own custom events" ON public.custom_tracked_events;

CREATE POLICY "Users can view their swimmers' custom events"
ON public.custom_tracked_events FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create custom events for their swimmers"
ON public.custom_tracked_events FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' custom events"
ON public.custom_tracked_events FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' custom events"
ON public.custom_tracked_events FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- Team Members RLS Policies
-- ============================================================================
-- Update team_members policies to check via swimmer ownership
DROP POLICY IF EXISTS "Users can view their own team memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can create their own team memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can update their own team memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can delete their own team memberships" ON public.team_members;

CREATE POLICY "Users can view their swimmers' team memberships"
ON public.team_members FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create team memberships for their swimmers"
ON public.team_members FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' team memberships"
ON public.team_members FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' team memberships"
ON public.team_members FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));
