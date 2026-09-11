-- Create training_goals table
CREATE TABLE public.training_goals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('time', 'distance', 'frequency', 'custom')),
  title TEXT NOT NULL,
  description TEXT,
  
  -- Time-based goal fields
  stroke TEXT,
  distance INTEGER,
  pool_type TEXT CHECK (pool_type IN ('SCY', 'SCM', 'LCM')),
  target_time_seconds DECIMAL(10, 2),
  
  -- Distance-based goal fields
  target_distance INTEGER,
  distance_period TEXT CHECK (distance_period IN ('daily', 'weekly', 'monthly')),
  
  -- Frequency-based goal fields
  target_frequency INTEGER, -- sessions per period
  frequency_period TEXT CHECK (frequency_period IN ('weekly', 'monthly')),
  
  -- Custom goal fields
  custom_target_value DECIMAL(10, 2),
  custom_unit TEXT,
  
  -- Common fields
  target_date DATE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'archived')),
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_training_goals_user_id ON public.training_goals(user_id);
CREATE INDEX idx_training_goals_team_id ON public.training_goals(team_id);
CREATE INDEX idx_training_goals_status ON public.training_goals(status);
CREATE INDEX idx_training_goals_type ON public.training_goals(goal_type);

-- RLS Policies
ALTER TABLE public.training_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own goals"
ON public.training_goals FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own goals"
ON public.training_goals FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals"
ON public.training_goals FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals"
ON public.training_goals FOR DELETE
USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_training_goals_updated_at
BEFORE UPDATE ON public.training_goals
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
