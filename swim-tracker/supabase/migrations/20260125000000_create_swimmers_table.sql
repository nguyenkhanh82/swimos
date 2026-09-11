-- Create swimmers table to track SwimCloud swimmer IDs and metadata
CREATE TABLE IF NOT EXISTS public.swimmers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swimcloud_id TEXT NOT NULL,
  swimcloud_person_id TEXT, -- Encoded person ID from USA Swimming API
  full_name TEXT,
  birth_date DATE,
  last_fetched_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT unique_user_swimcloud UNIQUE (user_id, swimcloud_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_swimmers_user_id ON public.swimmers(user_id);
CREATE INDEX IF NOT EXISTS idx_swimmers_swimcloud_id ON public.swimmers(swimcloud_id);

-- Enable RLS
ALTER TABLE public.swimmers ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own swimmers"
ON public.swimmers FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own swimmers"
ON public.swimmers FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own swimmers"
ON public.swimmers FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own swimmers"
ON public.swimmers FOR DELETE
USING (auth.uid() = user_id);

-- Trigger for automatic timestamp updates
CREATE TRIGGER update_swimmers_updated_at
BEFORE UPDATE ON public.swimmers
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
