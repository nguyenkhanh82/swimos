-- Migration: Create unified time standards structure
-- Created: 2026-01-26
-- Purpose: Consolidate all time standards (motivational and competition) into a single unified structure

-- Step 1: Create time_standard_types table
CREATE TABLE IF NOT EXISTS time_standard_types (
  id BIGSERIAL PRIMARY KEY,
  competition VARCHAR(100) NOT NULL,
  standard_type VARCHAR(50),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(competition, standard_type)
);

-- Create index for lookup
CREATE INDEX IF NOT EXISTS idx_time_standard_types_lookup 
  ON time_standard_types(competition, standard_type);

-- Step 2: Create unified_time_standards table
CREATE TABLE IF NOT EXISTS unified_time_standards (
  id BIGSERIAL PRIMARY KEY,
  event VARCHAR(50) NOT NULL,
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('WOMEN', 'MEN', 'F', 'M')),
  age_group VARCHAR(50), -- Nullable: '10 & Under', '11-12', '13-14', '15-16', '17-18', 'Open', '18_AND_UNDER', '19_AND_OVER', etc.
  scy_time VARCHAR(20), -- Formatted time string (e.g., '22.99', '1:48.19')
  lcm_time VARCHAR(20),
  scm_time VARCHAR(20),
  scy_seconds NUMERIC(10, 2),
  lcm_seconds NUMERIC(10, 2),
  scm_seconds NUMERIC(10, 2),
  year INTEGER NOT NULL DEFAULT 2026,
  standard_id BIGINT NOT NULL REFERENCES time_standard_types(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_event 
  ON unified_time_standards(event);
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_gender 
  ON unified_time_standards(gender);
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_age_group 
  ON unified_time_standards(age_group);
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_standard_id 
  ON unified_time_standards(standard_id);
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_year 
  ON unified_time_standards(year);

-- Composite index for common lookups
CREATE INDEX IF NOT EXISTS idx_unified_time_standards_lookup
  ON unified_time_standards(event, gender, age_group, standard_id, year);

-- Unique index to prevent duplicates (handles NULL age_group)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unified_time_standards_unique
  ON unified_time_standards(event, gender, COALESCE(age_group, ''), standard_id, year);

-- Step 3: Insert time standard types
-- Motivational standards (B, BB, A, AA, AAA, AAAA, AAAAA)
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('MOTIVATIONAL', 'B', 'USA Swimming B motivational time standard'),
('MOTIVATIONAL', 'BB', 'USA Swimming BB motivational time standard'),
('MOTIVATIONAL', 'A', 'USA Swimming A motivational time standard'),
('MOTIVATIONAL', 'AA', 'USA Swimming AA motivational time standard'),
('MOTIVATIONAL', 'AAA', 'USA Swimming AAA motivational time standard'),
('MOTIVATIONAL', 'AAAA', 'USA Swimming AAAA motivational time standard'),
('MOTIVATIONAL', 'AAAAA', 'USA Swimming AAAAA motivational time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- USA Swimming Qualifying standards
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('USA_QUALIFYING', 'REGULAR', 'USA Swimming Qualifying time standard'),
('USA_QUALIFYING', 'BONUS', 'USA Swimming Qualifying bonus time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- Speedo Sectionals
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('SPEEDO_SECTIONALS', NULL, 'Speedo Sectionals time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- Futures Championships
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('FUTURES_CHAMPIONSHIPS', NULL, 'USA Swimming Futures Championships time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- Winter Junior Championships
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('WINTER_JUNIOR_CHAMPIONSHIPS', 'REGULAR', 'Winter Junior Championships regular time standard'),
('WINTER_JUNIOR_CHAMPIONSHIPS', 'BONUS', 'Winter Junior Championships bonus time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- Toyota Nationals
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('TOYOTA_NATIONALS', NULL, 'Toyota US Open Nationals time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- USA Nationals
INSERT INTO time_standard_types (competition, standard_type, description) VALUES
('USA_NATIONALS', NULL, 'USA Swimming National Championships time standard')
ON CONFLICT (competition, standard_type) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE time_standard_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE unified_time_standards ENABLE ROW LEVEL SECURITY;

-- RLS Policies for time_standard_types
CREATE POLICY "Allow public read access to time_standard_types"
  ON time_standard_types FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert to time_standard_types"
  ON time_standard_types FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update to time_standard_types"
  ON time_standard_types FOR UPDATE
  TO authenticated
  USING (true);

-- RLS Policies for unified_time_standards
CREATE POLICY "Allow public read access to unified_time_standards"
  ON unified_time_standards FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert to unified_time_standards"
  ON unified_time_standards FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update to unified_time_standards"
  ON unified_time_standards FOR UPDATE
  TO authenticated
  USING (true);

-- Add comments
COMMENT ON TABLE time_standard_types IS 'Types of time standards (competition types and standard levels)';
COMMENT ON TABLE unified_time_standards IS 'Unified time standards table consolidating all motivational and competition standards';
COMMENT ON COLUMN unified_time_standards.event IS 'Event name (e.g., "50 FR", "100 Free", "200 BK")';
COMMENT ON COLUMN unified_time_standards.gender IS 'Gender: WOMEN/MEN or F/M';
COMMENT ON COLUMN unified_time_standards.age_group IS 'Age group (nullable): "10 & Under", "11-12", "13-14", "15-16", "17-18", "Open", "18_AND_UNDER", "19_AND_OVER", etc.';
COMMENT ON COLUMN unified_time_standards.standard_id IS 'Foreign key to time_standard_types table';
