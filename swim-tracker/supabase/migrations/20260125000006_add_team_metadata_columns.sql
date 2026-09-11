-- Add metadata columns to teams table for filtered queries
-- These columns store filter parameters used when fetching teams from SwimCloud

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='age_group') THEN
        ALTER TABLE teams ADD COLUMN age_group VARCHAR(20);
        RAISE NOTICE 'Added age_group column';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='event_course') THEN
        ALTER TABLE teams ADD COLUMN event_course VARCHAR(10);
        RAISE NOTICE 'Added event_course column';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='filter_gender') THEN
        ALTER TABLE teams ADD COLUMN filter_gender VARCHAR(1);
        RAISE NOTICE 'Added filter_gender column';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='filter_season_id') THEN
        ALTER TABLE teams ADD COLUMN filter_season_id INTEGER;
        RAISE NOTICE 'Added filter_season_id column';
    END IF;
    
    -- Add organization type and LSC code columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='organization_type') THEN
        ALTER TABLE teams ADD COLUMN organization_type VARCHAR(20) DEFAULT 'college';
        RAISE NOTICE 'Added organization_type column';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='lsc_code') THEN
        ALTER TABLE teams ADD COLUMN lsc_code VARCHAR(10);
        RAISE NOTICE 'Added lsc_code column';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='teams' AND column_name='region_code') THEN
        ALTER TABLE teams ADD COLUMN region_code VARCHAR(50);
        RAISE NOTICE 'Added region_code column';
    END IF;
END $$;

-- Create index for filtering
CREATE INDEX IF NOT EXISTS idx_teams_metadata 
ON teams(age_group, event_course, filter_gender, filter_season_id, lsc_code, organization_type);
