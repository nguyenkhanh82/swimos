"""
Initialize the database for SwimScraper
Run this script to create the database and schema
"""
import sys
import os

# Add the src directory to the path
current_dir = os.path.dirname(os.path.abspath(__file__))
src_dir = os.path.dirname(current_dir)
sys.path.insert(0, src_dir)

from SwimScraper.database import create_database, create_schema

if __name__ == "__main__":
    print("Initializing SwimScraper database...")
    try:
        create_database()
        create_schema()
        print("\nDatabase initialization complete!")
        print("\nYou can now run the scraper to populate the database.")
    except Exception as e:
        print(f"\nError initializing database: {e}")
        print("\nMake sure PostgreSQL is running:")
        print("  pg_ctl -D /opt/homebrew/var/postgresql@14 start")
        print("\nOr use:")
        print("  brew services start postgresql@14")
