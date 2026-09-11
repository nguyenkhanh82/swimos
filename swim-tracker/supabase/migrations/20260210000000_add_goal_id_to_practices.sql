ALTER TABLE public.practices ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE;
ALTER TABLE public.training_sets ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_practices_goal_id ON public.practices(goal_id);
CREATE INDEX IF NOT EXISTS idx_training_sets_goal_id ON public.training_sets(goal_id);
