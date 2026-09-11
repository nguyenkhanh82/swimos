-- Create scheduled_workouts table
CREATE TABLE IF NOT EXISTS public.scheduled_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    swimmer_id UUID NOT NULL REFERENCES public.swimmers(id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE,
    target_date DATE NOT NULL,
    focus_area TEXT NOT NULL,
    target_distance INT,
    target_duration_minutes INT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'missed')),
    practice_id UUID REFERENCES public.practices(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for querying scheduled workouts by swimmer, goal, and date
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_swimmer_id ON public.scheduled_workouts(swimmer_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_goal_id ON public.scheduled_workouts(goal_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_target_date ON public.scheduled_workouts(target_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_user_id ON public.scheduled_workouts(user_id);

-- Enable RLS
ALTER TABLE public.scheduled_workouts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own scheduled workouts"
    ON public.scheduled_workouts
    FOR SELECT
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.swimmers
            WHERE swimmers.id = scheduled_workouts.swimmer_id
            AND swimmers.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own scheduled workouts"
    ON public.scheduled_workouts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own scheduled workouts"
    ON public.scheduled_workouts
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own scheduled workouts"
    ON public.scheduled_workouts
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add trigger for updated_at
CREATE TRIGGER update_scheduled_workouts_updated_at
    BEFORE UPDATE ON public.scheduled_workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
