-- Make practice_id NOT NULL in training_sets and cascade delete
ALTER TABLE public.training_sets DROP CONSTRAINT IF EXISTS training_sets_practice_id_fkey;
ALTER TABLE public.training_sets ADD CONSTRAINT training_sets_practice_id_fkey FOREIGN KEY (practice_id) REFERENCES public.practices(id) ON DELETE CASCADE;
ALTER TABLE public.training_sets ALTER COLUMN practice_id SET NOT NULL;
