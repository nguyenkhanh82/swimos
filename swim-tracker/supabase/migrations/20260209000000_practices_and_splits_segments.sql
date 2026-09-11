-- Practice container and split segments for Log Practice plan
-- (a) practices table, (b) training_sets.practice_id, (c) training_set_splits segment fields

-- ============================================================================
-- 1. Create practices table (session that groups multiple sets)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.practices (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swimmer_id UUID NOT NULL REFERENCES public.swimmers(id) ON DELETE CASCADE,
  practice_date DATE NOT NULL,
  name TEXT,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_practices_user_id ON public.practices(user_id);
CREATE INDEX IF NOT EXISTS idx_practices_swimmer_id ON public.practices(swimmer_id);
CREATE INDEX IF NOT EXISTS idx_practices_practice_date ON public.practices(practice_date DESC);
CREATE INDEX IF NOT EXISTS idx_practices_team_id ON public.practices(team_id);

ALTER TABLE public.practices ENABLE ROW LEVEL SECURITY;

-- RLS: same as training_sets (user_owns_swimmer)
CREATE POLICY "Users can view their swimmers' practices"
ON public.practices FOR SELECT
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can create practices for their swimmers"
ON public.practices FOR INSERT
WITH CHECK (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can update their swimmers' practices"
ON public.practices FOR UPDATE
USING (public.user_owns_swimmer(swimmer_id));

CREATE POLICY "Users can delete their swimmers' practices"
ON public.practices FOR DELETE
USING (public.user_owns_swimmer(swimmer_id));

-- ============================================================================
-- 2. Add practice_id to training_sets (nullable; existing rows stay standalone)
-- ============================================================================
ALTER TABLE public.training_sets
ADD COLUMN IF NOT EXISTS practice_id UUID REFERENCES public.practices(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_training_sets_practice_id ON public.training_sets(practice_id);

-- ============================================================================
-- 3. Add segment fields to training_set_splits (IM by stroke, long distance 50/100)
-- ============================================================================
ALTER TABLE public.training_set_splits
ADD COLUMN IF NOT EXISTS segment_index INTEGER,
ADD COLUMN IF NOT EXISTS stroke_leg TEXT,
ADD COLUMN IF NOT EXISTS distance_per_segment INTEGER;

COMMENT ON COLUMN public.training_set_splits.segment_index IS '1-based index within rep (e.g. 1..4 for IM legs, 1..10 for 500 every 50)';
COMMENT ON COLUMN public.training_set_splits.stroke_leg IS 'For IM: Fly, Back, Breast, Free';
COMMENT ON COLUMN public.training_set_splits.distance_per_segment IS '50 or 100 for long-distance breakdown';
