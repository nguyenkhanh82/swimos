-- Create time_standards table for USA Swimming motivational times
CREATE TABLE public.time_standards (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  gender TEXT NOT NULL CHECK (gender IN ('M', 'F')),
  age_group TEXT NOT NULL CHECK (age_group IN ('10 & Under', '11-12', '13-14', '15-16', '17-18', 'Open')),
  course TEXT NOT NULL CHECK (course IN ('SCY', 'SCM', 'LCM')),
  event TEXT NOT NULL,
  stroke TEXT NOT NULL CHECK (stroke IN ('Free', 'Back', 'Breast', 'Fly', 'IM')),
  distance INTEGER NOT NULL,
  standard_level TEXT NOT NULL CHECK (standard_level IN ('B', 'BB', 'A', 'AA', 'AAA', 'AAAA', 'AAAAA')),
  time_seconds DECIMAL(10, 2) NOT NULL,
  effective_date DATE DEFAULT CURRENT_DATE,
  UNIQUE(gender, age_group, course, event, standard_level)
);

-- Indexes for efficient queries
CREATE INDEX idx_time_standards_lookup ON public.time_standards(gender, age_group, course, event, standard_level);
CREATE INDEX idx_time_standards_event ON public.time_standards(stroke, distance, course);
CREATE INDEX idx_time_standards_time ON public.time_standards(time_seconds);

-- RLS Policies (public read access for standards)
ALTER TABLE public.time_standards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Time standards are publicly readable"
ON public.time_standards FOR SELECT
TO public
USING (true);

-- Only admins can modify standards
CREATE POLICY "Only service role can modify standards"
ON public.time_standards FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Add comments for documentation
COMMENT ON TABLE public.time_standards IS 'USA Swimming motivational time standards by age group, gender, and course';
COMMENT ON COLUMN public.time_standards.gender IS 'M for Male, F for Female';
COMMENT ON COLUMN public.time_standards.age_group IS 'USA Swimming age group categories';
COMMENT ON COLUMN public.time_standards.course IS 'SCY (Short Course Yards), SCM (Short Course Meters), LCM (Long Course Meters)';
COMMENT ON COLUMN public.time_standards.standard_level IS 'B, BB, A, AA, AAA, AAAA, AAAAA motivational time standards';
