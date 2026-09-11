#!/usr/bin/env python3
"""
Migration script to add new columns to teams table
Run this if you have an existing database that needs the new columns
"""
from .database import get_connection
import psycopg2

def migrate_teams_schema():
    """Add new columns to teams table if they don't exist"""
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        print("Migrating teams table schema...")
        
        # Check and add columns
        cursor.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name='teams' AND column_name='team_type') THEN
                    ALTER TABLE teams ADD COLUMN team_type VARCHAR(20) DEFAULT 'college';
                    RAISE NOTICE 'Added team_type column';
                END IF;
                
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
        """)
        
        conn.commit()
        print("✓ Migration completed successfully")
        
        # Verify columns exist
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='teams' 
            AND column_name IN ('team_type', 'organization_type', 'lsc_code', 'region_code')
            ORDER BY column_name
        """)
        columns = [row[0] for row in cursor.fetchall()]
        print(f"✓ Verified columns: {', '.join(columns)}")
        
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error during migration: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    try:
        migrate_teams_schema()
    except Exception as e:
        print(f"Migration failed: {e}")
        import traceback
        traceback.print_exc()
