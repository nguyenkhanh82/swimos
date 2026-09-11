DROP TABLE IF EXISTS public.nutrition_targets CASCADE;
DROP TABLE IF EXISTS public.nutrition_logs CASCADE;

-- Create nutrition targets table
CREATE TABLE public.nutrition_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    swimmer_id UUID NOT NULL REFERENCES public.swimmers(id) ON DELETE CASCADE,
    calories_target INTEGER NOT NULL DEFAULT 2500,
    protein_target INTEGER NOT NULL DEFAULT 150,
    carbs_target INTEGER NOT NULL DEFAULT 300,
    fat_target INTEGER NOT NULL DEFAULT 75,
    sugar_target INTEGER NOT NULL DEFAULT 50,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(swimmer_id)
);

-- Create nutrition logs table
CREATE TABLE public.nutrition_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    swimmer_id UUID NOT NULL REFERENCES public.swimmers(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    meal_type TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    calories INTEGER DEFAULT 0,
    protein INTEGER DEFAULT 0,
    carbs INTEGER DEFAULT 0,
    fat INTEGER DEFAULT 0,
    sugar INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for nutrition_targets
ALTER TABLE public.nutrition_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own nutrition targets" ON public.nutrition_targets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own nutrition targets" ON public.nutrition_targets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their accessible swimmer nutrition targets" ON public.nutrition_targets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own nutrition targets" ON public.nutrition_targets
    FOR DELETE USING (auth.uid() = user_id);

-- RLS for nutrition_logs
ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own nutrition logs" ON public.nutrition_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own nutrition logs" ON public.nutrition_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their accessible swimmer nutrition logs" ON public.nutrition_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own nutrition logs" ON public.nutrition_logs
    FOR DELETE USING (auth.uid() = user_id);

-- Create automatic timestamp trigger
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.nutrition_targets
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.nutrition_logs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create an edge function bucket for food images if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('food_images', 'food_images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Any user can view food images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'food_images');

CREATE POLICY "Authenticated users can upload food images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'food_images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own food images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'food_images' AND auth.uid()::text = (storage.foldername(name))[1]);
