"""
Database connection and schema management for SwimScraper
"""
import psycopg2
from psycopg2.extras import execute_values
from psycopg2 import sql
import os
from typing import Optional, Dict, List, Any

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'swimscraper'),
    'user': os.getenv('DB_USER', os.getenv('USER', 'postgres')),
    'password': os.getenv('DB_PASSWORD', '')
}

def get_connection():
    """Get a database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to database: {e}")
        raise

def create_database():
    """Create the database if it doesn't exist"""
    # Connect to default postgres database to create our database
    config = DB_CONFIG.copy()
    config['database'] = 'postgres'
    
    try:
        conn = psycopg2.connect(**config)
        conn.autocommit = True
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (DB_CONFIG['database'],)
        )
        exists = cursor.fetchone()
        
        if not exists:
            cursor.execute(
                sql.SQL("CREATE DATABASE {}").format(
                    sql.Identifier(DB_CONFIG['database'])
                )
            )
            print(f"Database '{DB_CONFIG['database']}' created successfully")
        else:
            print(f"Database '{DB_CONFIG['database']}' already exists")
        
        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(f"Error creating database: {e}")
        raise

def create_schema():
    """Create all database tables"""
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        # Teams table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS teams (
                team_id INTEGER PRIMARY KEY,
                team_name VARCHAR(255) NOT NULL,
                team_state VARCHAR(50),
                team_division VARCHAR(100),
                team_division_id VARCHAR(50),
                team_conference VARCHAR(100),
                team_conference_id VARCHAR(50),
                team_type VARCHAR(20) DEFAULT 'college',
                organization_type VARCHAR(20) DEFAULT 'college',
                lsc_code VARCHAR(10),
                region_code VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(team_id)
            )
        """)
        
        # Add new columns if they don't exist (for existing databases)
        # Use DO block to check if column exists before adding
        cursor.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='team_type') THEN
                    ALTER TABLE teams ADD COLUMN team_type VARCHAR(20) DEFAULT 'college';
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='organization_type') THEN
                    ALTER TABLE teams ADD COLUMN organization_type VARCHAR(20) DEFAULT 'college';
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='lsc_code') THEN
                    ALTER TABLE teams ADD COLUMN lsc_code VARCHAR(10);
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='region_code') THEN
                    ALTER TABLE teams ADD COLUMN region_code VARCHAR(50);
                END IF;
                
                -- Add metadata columns for filtered team queries
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='age_group') THEN
                    ALTER TABLE teams ADD COLUMN age_group VARCHAR(20);
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='event_course') THEN
                    ALTER TABLE teams ADD COLUMN event_course VARCHAR(10);
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='filter_gender') THEN
                    ALTER TABLE teams ADD COLUMN filter_gender VARCHAR(1);
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='filter_season_id') THEN
                    ALTER TABLE teams ADD COLUMN filter_season_id INTEGER;
                END IF;
            END $$;
        """)
        
        # Swimmers table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS swimmers (
                swimmer_id INTEGER PRIMARY KEY,
                swimmer_name VARCHAR(255) NOT NULL,
                hometown_state VARCHAR(50),
                hometown_city VARCHAR(100),
                hs_power_index DECIMAL(5,2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(swimmer_id)
            )
        """)
        
        # Rosters table (many-to-many relationship between teams and swimmers)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS rosters (
                id SERIAL PRIMARY KEY,
                team_id INTEGER REFERENCES teams(team_id),
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
                grade VARCHAR(20),
                season_id INTEGER,
                year INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(team_id, swimmer_id, gender, season_id)
            )
        """)
        
        # Swimmer events table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS swimmer_events (
                id SERIAL PRIMARY KEY,
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                event_name VARCHAR(100) NOT NULL,
                event_id VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(swimmer_id, event_name)
            )
        """)
        
        # Swimmer times table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS swimmer_times (
                id SERIAL PRIMARY KEY,
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                event_name VARCHAR(100) NOT NULL,
                event_id VARCHAR(50),
                time VARCHAR(50),
                meet_name VARCHAR(255),
                year VARCHAR(10),
                date VARCHAR(100),
                additional_info TEXT,
                course_type VARCHAR(10) DEFAULT 'SCY',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Meets table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS meets (
                meet_id INTEGER PRIMARY KEY,
                meet_name VARCHAR(255) NOT NULL,
                meet_date VARCHAR(100),
                meet_location VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(meet_id)
            )
        """)
        
        # Team meets table (many-to-many relationship)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS team_meets (
                id SERIAL PRIMARY KEY,
                team_id INTEGER REFERENCES teams(team_id),
                meet_id INTEGER REFERENCES meets(meet_id),
                year INTEGER,
                season_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(team_id, meet_id, year)
            )
        """)
        
        # Meet events table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS meet_events (
                id SERIAL PRIMARY KEY,
                meet_id INTEGER REFERENCES meets(meet_id),
                event_name VARCHAR(100) NOT NULL,
                event_id VARCHAR(50),
                event_href VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(meet_id, event_name)
            )
        """)
        
        # College meet results table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS college_meet_results (
                id SERIAL PRIMARY KEY,
                meet_id INTEGER REFERENCES meets(meet_id),
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                team_id INTEGER REFERENCES teams(team_id),
                event_name VARCHAR(100) NOT NULL,
                event_id VARCHAR(50),
                event_type VARCHAR(50),
                time VARCHAR(50),
                score VARCHAR(50),
                improvement VARCHAR(50),
                course_type VARCHAR(10) DEFAULT 'SCY',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Pro meet results table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS pro_meet_results (
                id SERIAL PRIMARY KEY,
                meet_id INTEGER REFERENCES meets(meet_id),
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                team_id INTEGER,
                event_name VARCHAR(100) NOT NULL,
                event_id VARCHAR(50),
                event_type VARCHAR(50),
                time VARCHAR(50),
                fina_score VARCHAR(50),
                improvement VARCHAR(50),
                course_type VARCHAR(10) DEFAULT 'LCM',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Team rankings table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS team_rankings (
                id SERIAL PRIMARY KEY,
                team_id INTEGER REFERENCES teams(team_id),
                team_name VARCHAR(255) NOT NULL,
                gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
                season_id INTEGER,
                year INTEGER,
                swimcloud_points VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(team_id, gender, season_id)
            )
        """)
        
        # HS recruit rankings table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS hs_recruit_rankings (
                id SERIAL PRIMARY KEY,
                swimmer_id INTEGER REFERENCES swimmers(swimmer_id),
                class_year INTEGER NOT NULL,
                gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
                state VARCHAR(50),
                city VARCHAR(100),
                hs_power_index VARCHAR(50),
                team_id INTEGER,
                team_name VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(swimmer_id, class_year, gender)
            )
        """)
        
        # Create indexes for better query performance
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_rosters_team_id ON rosters(team_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_rosters_swimmer_id ON rosters(swimmer_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_swimmer_times_swimmer_id ON swimmer_times(swimmer_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_swimmer_times_event_name ON swimmer_times(event_name)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_meet_results_meet_id ON college_meet_results(meet_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_meet_results_swimmer_id ON college_meet_results(swimmer_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_team_meets_team_id ON team_meets(team_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_team_meets_meet_id ON team_meets(meet_id)")
        
        conn.commit()
        print("Database schema created successfully")
        
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error creating schema: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_teams(teams_data: List[Dict[str, Any]]):
    """Save teams data to database"""
    if not teams_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for team in teams_data:
            cursor.execute("""
                INSERT INTO teams (team_id, team_name, team_state, team_division, 
                                 team_division_id, team_conference, team_conference_id,
                                 team_type, organization_type, lsc_code, region_code,
                                 age_group, event_course, filter_gender, filter_season_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (team_id) 
                DO UPDATE SET 
                    team_name = EXCLUDED.team_name,
                    team_state = EXCLUDED.team_state,
                    team_division = EXCLUDED.team_division,
                    team_division_id = EXCLUDED.team_division_id,
                    team_conference = EXCLUDED.team_conference,
                    team_conference_id = EXCLUDED.team_conference_id,
                    team_type = COALESCE(EXCLUDED.team_type, teams.team_type),
                    organization_type = COALESCE(EXCLUDED.organization_type, teams.organization_type),
                    lsc_code = COALESCE(EXCLUDED.lsc_code, teams.lsc_code),
                    region_code = COALESCE(EXCLUDED.region_code, teams.region_code),
                    age_group = COALESCE(EXCLUDED.age_group, teams.age_group),
                    event_course = COALESCE(EXCLUDED.event_course, teams.event_course),
                    filter_gender = COALESCE(EXCLUDED.filter_gender, teams.filter_gender),
                    filter_season_id = COALESCE(EXCLUDED.filter_season_id, teams.filter_season_id),
                    updated_at = CURRENT_TIMESTAMP
            """, (
                team.get('team_ID'),
                team.get('team_name'),
                team.get('team_state'),
                team.get('team_division'),
                team.get('team_division_ID'),
                team.get('team_conference'),
                team.get('team_conference_ID'),
                team.get('team_type', 'college'),
                team.get('organization_type', team.get('team_type', 'college')),
                team.get('lsc_code'),
                team.get('region_code'),
                team.get('age_group'),
                team.get('event_course'),
                team.get('gender'),  # Store as filter_gender
                team.get('season_id')
            ))
        
        conn.commit()
        print(f"Saved {len(teams_data)} teams to database")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving teams: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_roster(roster_data: List[Dict[str, Any]], team_id: int, gender: str, season_id: Optional[int] = None, year: Optional[int] = None):
    """Save roster data to database"""
    if not roster_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for swimmer in roster_data:
            # First, save/update swimmer
            cursor.execute("""
                INSERT INTO swimmers (swimmer_id, swimmer_name, hometown_state, 
                                    hometown_city, hs_power_index)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (swimmer_id) 
                DO UPDATE SET 
                    swimmer_name = EXCLUDED.swimmer_name,
                    hometown_state = EXCLUDED.hometown_state,
                    hometown_city = EXCLUDED.hometown_city,
                    hs_power_index = EXCLUDED.hs_power_index,
                    updated_at = CURRENT_TIMESTAMP
            """, (
                swimmer.get('swimmer_ID'),
                swimmer.get('swimmer_name'),
                swimmer.get('hometown_state'),
                swimmer.get('hometown_city'),
                swimmer.get('HS_power_index') if swimmer.get('HS_power_index') != -1 else None
            ))
            
            # Then, save roster entry
            cursor.execute("""
                INSERT INTO rosters (team_id, swimmer_id, gender, grade, season_id, year)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (team_id, swimmer_id, gender, season_id) DO NOTHING
            """, (
                team_id,
                swimmer.get('swimmer_ID'),
                gender,
                swimmer.get('grade'),
                season_id,
                year
            ))
        
        conn.commit()
        print(f"Saved {len(roster_data)} swimmers to roster")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving roster: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_swimmer_events(swimmer_id: int, events: List[str]):
    """Save swimmer events to database"""
    if not events:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for event_name in events:
            cursor.execute("""
                INSERT INTO swimmer_events (swimmer_id, event_name)
                VALUES (%s, %s)
                ON CONFLICT (swimmer_id, event_name) DO NOTHING
            """, (swimmer_id, event_name))
        
        conn.commit()
        print(f"Saved {len(events)} events for swimmer {swimmer_id}")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving swimmer events: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_swimmer_times(swimmer_id: int, times_data: List[Dict[str, Any]]):
    """Save swimmer times to database"""
    if not times_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for time_entry in times_data:
            # Determine course type from event name
            event_name = time_entry.get('event', '')
            if ' L ' in event_name or event_name.endswith('L'):
                course_type = 'LCM'
            elif ' S ' in event_name or event_name.endswith('S'):
                course_type = 'SCM'
            else:
                course_type = 'SCY'  # Default to SCY
            
            # Use course_type from entry if provided
            course_type = time_entry.get('course_type', course_type)
            
            cursor.execute("""
                INSERT INTO swimmer_times (swimmer_id, event_name, event_id, time, 
                                         meet_name, year, date, additional_info, course_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                swimmer_id,
                time_entry.get('event'),
                time_entry.get('event_ID'),
                time_entry.get('time'),
                time_entry.get('meet_name'),
                time_entry.get('year'),
                time_entry.get('date'),
                str(time_entry.get('additional_info', [])) if time_entry.get('additional_info') else None,
                course_type
            ))
        
        conn.commit()
        print(f"Saved {len(times_data)} times for swimmer {swimmer_id}")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving swimmer times: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_meets(meets_data: List[Dict[str, Any]], team_id: int, year: Optional[int] = None):
    """Save meets data to database"""
    if not meets_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for meet in meets_data:
            meet_id = meet.get('meet_ID')
            
            # Save meet
            cursor.execute("""
                INSERT INTO meets (meet_id, meet_name, meet_date, meet_location)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (meet_id) 
                DO UPDATE SET 
                    meet_name = EXCLUDED.meet_name,
                    meet_date = EXCLUDED.meet_date,
                    meet_location = EXCLUDED.meet_location,
                    updated_at = CURRENT_TIMESTAMP
            """, (
                meet_id,
                meet.get('meet_name'),
                meet.get('meet_date'),
                meet.get('meet_location')
            ))
            
            # Save team-meet relationship
            cursor.execute("""
                INSERT INTO team_meets (team_id, meet_id, year)
                VALUES (%s, %s, %s)
                ON CONFLICT (team_id, meet_id, year) DO NOTHING
            """, (team_id, meet_id, year))
        
        conn.commit()
        print(f"Saved {len(meets_data)} meets to database")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving meets: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_meet_results(results_data: List[Dict[str, Any]], is_pro: bool = False):
    """Save meet results to database"""
    if not results_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        table_name = 'pro_meet_results' if is_pro else 'college_meet_results'
        
        for result in results_data:
            # Ensure swimmer exists
            if result.get('swimmer_ID'):
                cursor.execute("""
                    INSERT INTO swimmers (swimmer_id, swimmer_name)
                    VALUES (%s, %s)
                    ON CONFLICT (swimmer_id) DO NOTHING
                """, (result.get('swimmer_ID'), result.get('swimmer_name')))
            
            # Ensure team exists (for college meets)
            if not is_pro and result.get('team_ID'):
                cursor.execute("""
                    INSERT INTO teams (team_id, team_name)
                    VALUES (%s, %s)
                    ON CONFLICT (team_id) DO NOTHING
                """, (result.get('team_ID'), result.get('team_name')))
            
            # Determine course type
            event_name = result.get('event_name', '')
            if ' L ' in event_name or event_name.endswith('L'):
                course_type = 'LCM'
            elif ' S ' in event_name or event_name.endswith('S'):
                course_type = 'SCM'
            else:
                course_type = 'SCY' if not is_pro else 'LCM'
            
            # Use course_type from result if provided
            course_type = result.get('course_type', course_type)
            
            # Insert result
            if is_pro:
                cursor.execute(f"""
                    INSERT INTO {table_name} 
                    (meet_id, swimmer_id, team_id, event_name, event_id, 
                     event_type, time, fina_score, improvement, course_type)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    result.get('meet_ID'),
                    result.get('swimmer_ID'),
                    result.get('team_ID') if result.get('team_ID') != -1 else None,
                    result.get('event_name'),
                    result.get('event_ID'),
                    result.get('event_type'),
                    result.get('time'),
                    result.get('FINA_score'),
                    result.get('Improvement'),
                    course_type
                ))
            else:
                cursor.execute(f"""
                    INSERT INTO {table_name} 
                    (meet_id, swimmer_id, team_id, event_name, event_id, 
                     event_type, time, score, improvement, course_type)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    result.get('meet_ID'),
                    result.get('swimmer_ID'),
                    result.get('team_ID'),
                    result.get('event_name'),
                    result.get('event_ID'),
                    result.get('event_type'),
                    result.get('time'),
                    result.get('score'),
                    result.get('Improvement'),
                    course_type
                ))
        
        conn.commit()
        print(f"Saved {len(results_data)} meet results to database")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving meet results: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_team_rankings(rankings_data: List[Dict[str, Any]], gender: str, season_id: Optional[int] = None, year: Optional[int] = None):
    """Save team rankings to database"""
    if not rankings_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for ranking in rankings_data:
            team_id = ranking.get('team_ID')
            team_name = ranking.get('team_name')
            
            # Ensure team exists
            cursor.execute("""
                INSERT INTO teams (team_id, team_name)
                VALUES (%s, %s)
                ON CONFLICT (team_id) DO NOTHING
            """, (team_id, team_name))
            
            # Save ranking
            cursor.execute("""
                INSERT INTO team_rankings (team_id, team_name, gender, season_id, year, swimcloud_points)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (team_id, gender, season_id) 
                DO UPDATE SET 
                    swimcloud_points = EXCLUDED.swimcloud_points
            """, (
                team_id,
                team_name,
                gender,
                season_id,
                year,
                ranking.get('swimcloud_points')
            ))
        
        conn.commit()
        print(f"Saved {len(rankings_data)} team rankings to database")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving team rankings: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

def save_hs_recruit_rankings(rankings_data: List[Dict[str, Any]], class_year: int, gender: str):
    """Save HS recruit rankings to database"""
    if not rankings_data:
        return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        for recruit in rankings_data:
            swimmer_id = recruit.get('swimmer_ID')
            
            # Save swimmer
            cursor.execute("""
                INSERT INTO swimmers (swimmer_id, swimmer_name, hometown_state, hometown_city, hs_power_index)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (swimmer_id) 
                DO UPDATE SET 
                    swimmer_name = EXCLUDED.swimmer_name,
                    hometown_state = EXCLUDED.hometown_state,
                    hometown_city = EXCLUDED.hometown_city,
                    hs_power_index = EXCLUDED.hs_power_index,
                    updated_at = CURRENT_TIMESTAMP
            """, (
                swimmer_id,
                recruit.get('swimmer_name'),
                recruit.get('hometown_state'),
                recruit.get('hometown_city'),
                recruit.get('HS_power_index') if recruit.get('HS_power_index') and recruit.get('HS_power_index') != 'None' else None
            ))
            
            # Save ranking
            cursor.execute("""
                INSERT INTO hs_recruit_rankings 
                (swimmer_id, class_year, gender, state, city, hs_power_index, team_id, team_name)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (swimmer_id, class_year, gender) 
                DO UPDATE SET 
                    state = EXCLUDED.state,
                    city = EXCLUDED.city,
                    hs_power_index = EXCLUDED.hs_power_index,
                    team_id = EXCLUDED.team_id,
                    team_name = EXCLUDED.team_name
            """, (
                swimmer_id,
                class_year,
                gender,
                recruit.get('hometown_state'),
                recruit.get('hometown_city'),
                recruit.get('HS_power_index') if recruit.get('HS_power_index') and recruit.get('HS_power_index') != 'None' else None,
                recruit.get('team_ID') if recruit.get('team_ID') and recruit.get('team_ID') != 'None' else None,
                recruit.get('team_name') if recruit.get('team_name') and recruit.get('team_name') != 'None' else None
            ))
            
        conn.commit()
        print(f"Saved {len(rankings_data)} recruit rankings to database")
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error saving recruit rankings: {e}")
        raise
    finally:
        cursor.close()
        conn.close()
