-- Add stroke and distance to swim_times for edge function and app queries
-- (goal_progress_service, goal_suggestions_service query by stroke/distance)
ALTER TABLE public.swim_times
  ADD COLUMN IF NOT EXISTS stroke TEXT CHECK (stroke IN ('Free', 'Back', 'Breast', 'Fly', 'IM'));
ALTER TABLE public.swim_times
  ADD COLUMN IF NOT EXISTS distance INTEGER;

CREATE INDEX IF NOT EXISTS idx_swim_times_stroke_distance ON public.swim_times(swimmer_id, stroke, distance) WHERE stroke IS NOT NULL AND distance IS NOT NULL;
