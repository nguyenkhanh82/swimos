-- Create goal_progress_entries table for manual progress tracking
CREATE TABLE public.goal_progress_entries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  goal_id UUID NOT NULL REFERENCES public.training_goals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  progress_value DECIMAL(10, 2) NOT NULL,
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_goal_progress_entries_goal_id ON public.goal_progress_entries(goal_id);
CREATE INDEX idx_goal_progress_entries_user_id ON public.goal_progress_entries(user_id);
CREATE INDEX idx_goal_progress_entries_recorded_at ON public.goal_progress_entries(recorded_at DESC);

-- RLS Policies
ALTER TABLE public.goal_progress_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own progress entries"
ON public.goal_progress_entries FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own progress entries"
ON public.goal_progress_entries FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress entries"
ON public.goal_progress_entries FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own progress entries"
ON public.goal_progress_entries FOR DELETE
USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_goal_progress_entries_updated_at
BEFORE UPDATE ON public.goal_progress_entries
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
