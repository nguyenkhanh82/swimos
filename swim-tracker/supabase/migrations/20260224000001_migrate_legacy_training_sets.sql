-- Safely create practices for any existing legacy standalone training_sets.
-- Groups them based on swimmer and date.
DO $$ 
DECLARE
    r RECORD;
    new_practice_id UUID;
BEGIN
    FOR r IN 
        SELECT DISTINCT ts.swimmer_id, ts.training_date, s.user_id 
        FROM public.training_sets ts
        JOIN public.swimmers s ON ts.swimmer_id = s.id
        WHERE ts.practice_id IS NULL
    LOOP
        -- 1. Check if a practice already exists for this swimmer on this precise date
        SELECT id INTO new_practice_id 
        FROM public.practices 
        WHERE swimmer_id = r.swimmer_id AND practice_date = r.training_date
        LIMIT 1;

        -- 2. If no practice exists, create a placeholder practice for that day
        IF new_practice_id IS NULL THEN
            INSERT INTO public.practices (user_id, swimmer_id, practice_date, name)
            VALUES (r.user_id, r.swimmer_id, r.training_date, 'Legacy Practice Log')
            RETURNING id INTO new_practice_id;
        END IF;

        -- 3. Tie all orphaned solitary sets for this swimmer & date to the new/existing Practice
        UPDATE public.training_sets
        SET practice_id = new_practice_id
        WHERE swimmer_id = r.swimmer_id 
          AND training_date = r.training_date 
          AND practice_id IS NULL;
    END LOOP;
END $$;

-- Ensure constraints are fully applied (now that existing sets have practice_id assigned)
ALTER TABLE public.training_sets DROP CONSTRAINT IF EXISTS training_sets_practice_id_fkey;
ALTER TABLE public.training_sets ADD CONSTRAINT training_sets_practice_id_fkey FOREIGN KEY (practice_id) REFERENCES public.practices(id) ON DELETE CASCADE;
ALTER TABLE public.training_sets ALTER COLUMN practice_id SET NOT NULL;
