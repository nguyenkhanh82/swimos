-- Create teams table
CREATE TABLE public.teams (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  team_type TEXT NOT NULL CHECK (team_type IN ('regular', 'camp', 'private_coach', 'self')),
  level TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sportengines_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team_members table (Many-to-many: Users ↔ Teams)
CREATE TABLE public.team_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('active', 'past')),
  joined_date DATE NOT NULL DEFAULT CURRENT_DATE,
  left_date DATE,
  role TEXT NOT NULL DEFAULT 'swimmer',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT unique_user_team UNIQUE (user_id, team_id)
);

-- Create coaches table
CREATE TABLE public.coaches (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create team_coaches table (Many-to-many: Teams ↔ Coaches)
CREATE TABLE public.team_coaches (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES public.coaches(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT unique_team_coach UNIQUE (team_id, coach_id)
);

-- Create custom_tracked_events table
CREATE TABLE public.custom_tracked_events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  stroke TEXT CHECK (stroke IN ('Free', 'Back', 'Breast', 'Fly', 'IM')),
  distance INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add team_id to training_sets table (nullable for backward compatibility)
ALTER TABLE public.training_sets
ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON public.teams(created_by);
CREATE INDEX IF NOT EXISTS idx_teams_is_active ON public.teams(is_active);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_status ON public.team_members(status);
CREATE INDEX IF NOT EXISTS idx_coaches_created_by ON public.coaches(created_by);
CREATE INDEX IF NOT EXISTS idx_team_coaches_team_id ON public.team_coaches(team_id);
CREATE INDEX IF NOT EXISTS idx_team_coaches_coach_id ON public.team_coaches(coach_id);
CREATE INDEX IF NOT EXISTS idx_custom_tracked_events_user_id ON public.custom_tracked_events(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_tracked_events_team_id ON public.custom_tracked_events(team_id);
CREATE INDEX IF NOT EXISTS idx_training_sets_team_id ON public.training_sets(team_id);

-- Enable RLS on all new tables
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_coaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_tracked_events ENABLE ROW LEVEL SECURITY;

-- RLS policies for teams
CREATE POLICY "Users can view teams they created or are members of" ON public.teams
  FOR SELECT USING (
    created_by = auth.uid() OR
    id IN (SELECT team_id FROM public.team_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create their own teams" ON public.teams
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update teams they created" ON public.teams
  FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Users can delete teams they created" ON public.teams
  FOR DELETE USING (created_by = auth.uid());

-- RLS policies for team_members
CREATE POLICY "Users can view their own team memberships" ON public.team_members
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own team memberships" ON public.team_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own team memberships" ON public.team_members
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own team memberships" ON public.team_members
  FOR DELETE USING (user_id = auth.uid());

-- RLS policies for coaches
CREATE POLICY "Users can view coaches they created or coaches from their teams" ON public.coaches
  FOR SELECT USING (
    created_by = auth.uid() OR
    id IN (
      SELECT tc.coach_id 
      FROM public.team_coaches tc
      JOIN public.team_members tm ON tc.team_id = tm.team_id
      WHERE tm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create coaches" ON public.coaches
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update coaches they created" ON public.coaches
  FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Users can delete coaches they created" ON public.coaches
  FOR DELETE USING (created_by = auth.uid());

-- RLS policies for team_coaches
CREATE POLICY "Users can view team coaches for their teams" ON public.team_coaches
  FOR SELECT USING (
    team_id IN (
      SELECT team_id FROM public.team_members WHERE user_id = auth.uid()
    ) OR
    team_id IN (
      SELECT id FROM public.teams WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Users can add coaches to teams they created" ON public.team_coaches
  FOR INSERT WITH CHECK (
    team_id IN (SELECT id FROM public.teams WHERE created_by = auth.uid())
  );

CREATE POLICY "Users can update team coaches for teams they created" ON public.team_coaches
  FOR UPDATE USING (
    team_id IN (SELECT id FROM public.teams WHERE created_by = auth.uid())
  );

CREATE POLICY "Users can delete team coaches from teams they created" ON public.team_coaches
  FOR DELETE USING (
    team_id IN (SELECT id FROM public.teams WHERE created_by = auth.uid())
  );

-- RLS policies for custom_tracked_events
CREATE POLICY "Users can view their own custom events" ON public.custom_tracked_events
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own custom events" ON public.custom_tracked_events
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own custom events" ON public.custom_tracked_events
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own custom events" ON public.custom_tracked_events
  FOR DELETE USING (user_id = auth.uid());

-- Add triggers for updated_at
CREATE TRIGGER update_teams_updated_at
  BEFORE UPDATE ON public.teams
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_team_members_updated_at
  BEFORE UPDATE ON public.team_members
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_coaches_updated_at
  BEFORE UPDATE ON public.coaches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_custom_tracked_events_updated_at
  BEFORE UPDATE ON public.custom_tracked_events
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
