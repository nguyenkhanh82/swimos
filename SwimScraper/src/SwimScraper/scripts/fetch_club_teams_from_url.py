#!/usr/bin/env python3
"""
Fetch club teams from a specific SwimCloud URL with filters
Extracts teams based on URL query parameters and saves to Supabase
"""
import argparse
import sys
import os

from ..scrapers import clubs
from .. import database as db


def main():
    parser = argparse.ArgumentParser(
        description='Fetch club teams from a specific SwimCloud URL and save to Supabase',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Fetch teams from a filtered URL
  python -m SwimScraper.scripts.fetch_club_teams_from_url \\
    --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&page=1&region=lsc_PN&seasonId=29&sortBy=top50"
  
  # Test without saving to database
  python -m SwimScraper.scripts.fetch_club_teams_from_url \\
    --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F" \\
    --no-save
        """
    )
    
    parser.add_argument('--url', type=str, required=True,
                       help='Full SwimCloud URL with query parameters')
    parser.add_argument('--no-save', action='store_true',
                       help='Don\'t save to database (for testing)')
    
    args = parser.parse_args()
    
    # Verify database connection if saving
    if not args.no_save:
        try:
            conn = db.get_connection()
            conn.close()
            print("✓ Database connection verified")
        except Exception as e:
            print(f"✗ Database connection error: {e}")
            print("  Make sure DATABASE_URL or DB_* environment variables are set")
            sys.exit(1)
    
    try:
        print(f"\n{'='*60}")
        print(f"Fetching club teams from URL")
        print(f"{'='*60}")
        print(f"URL: {args.url}\n")
        
        # Fetch teams from URL
        teams = clubs.get_club_teams_from_url(args.url, save_to_db=not args.no_save)
        
        print(f"\n{'='*60}")
        print(f"SUMMARY")
        print(f"{'='*60}")
        print(f"Total teams found: {len(teams)}")
        
        if teams:
            print(f"\nFirst 10 teams:")
            for i, team in enumerate(teams[:10], 1):
                print(f"  {i}. {team['team_name']} (ID: {team['team_ID']})")
            
            if not args.no_save:
                print(f"\n✓ Teams saved to database")
            else:
                print(f"\n⚠ Teams NOT saved (--no-save flag used)")
        else:
            print("\n✗ No teams found")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
