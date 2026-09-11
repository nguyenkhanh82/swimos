-- Create goal_milestones table for checkpoint tracking
CREATE TABLE public.goal_milestones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  goal_id UUID NOT NULL REFERENCES public.training_goals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_value DECIMAL(10, 2) NOT NULL,
  target_date DATE,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_goal_milestones_goal_id ON public.goal_milestones(goal_id);
CREATE INDEX idx_goal_milestones_sort_order ON public.goal_milestones(goal_id, sort_order);
CREATE INDEX idx_goal_milestones_completed ON public.goal_milestones(goal_id, is_completed);

-- RLS Policies
ALTER TABLE public.goal_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view milestones for their goals"
ON public.goal_milestones FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.training_goals
    WHERE training_goals.id = goal_milestones.goal_id
    AND training_goals.user_id = auth.uid()
  )
);

CREATE POLICY "Users can create milestones for their goals"
ON public.goal_milestones FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.training_goals
    WHERE training_goals.id = goal_milestones.goal_id
    AND training_goals.user_id = auth.uid()
  )
);

CREATE POLICY "Users can update milestones for their goals"
ON public.goal_milestones FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.training_goals
    WHERE training_goals.id = goal_milestones.goal_id
    AND training_goals.user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete milestones for their goals"
ON public.goal_milestones FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.training_goals
    WHERE training_goals.id = goal_milestones.goal_id
    AND training_goals.user_id = auth.uid()
  )
);

-- Trigger for updated_at
CREATE TRIGGER update_goal_milestones_updated_at
BEFORE UPDATE ON public.goal_milestones
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
