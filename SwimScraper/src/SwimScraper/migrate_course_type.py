"""
Migration script to add course_type columns to existing database tables
Run this if you already have a database without course_type columns
"""
from database import get_connection

def migrate_course_type():
    """Add course_type columns to existing tables"""
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        # Add course_type to swimmer_times if it doesn't exist
        cursor.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='swimmer_times' AND column_name='course_type'
                ) THEN
                    ALTER TABLE swimmer_times ADD COLUMN course_type VARCHAR(10) DEFAULT 'SCY';
                END IF;
            END $$;
        """)
        
        # Add course_type to college_meet_results if it doesn't exist
        cursor.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='college_meet_results' AND column_name='course_type'
                ) THEN
                    ALTER TABLE college_meet_results ADD COLUMN course_type VARCHAR(10) DEFAULT 'SCY';
                END IF;
            END $$;
        """)
        
        # Add course_type to pro_meet_results if it doesn't exist
        cursor.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='pro_meet_results' AND column_name='course_type'
                ) THEN
                    ALTER TABLE pro_meet_results ADD COLUMN course_type VARCHAR(10) DEFAULT 'LCM';
                END IF;
            END $$;
        """)
        
        conn.commit()
        print("Migration completed successfully!")
        print("Added course_type columns to:")
        print("  - swimmer_times (default: SCY)")
        print("  - college_meet_results (default: SCY)")
        print("  - pro_meet_results (default: LCM)")
        
    except Exception as e:
        conn.rollback()
        print(f"Error during migration: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    print("Migrating database to add course_type columns...")
    migrate_course_type()
