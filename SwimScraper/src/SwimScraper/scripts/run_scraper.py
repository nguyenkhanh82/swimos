#!/usr/bin/env python3
"""
Example script to run the SwimScraper with database storage
"""
from SwimScraper import SwimScraperDB as ss

def main():
    """Example usage of SwimScraper with database"""
    print("SwimScraper with Database Storage")
    print("=" * 50)
    
    # Example 1: Get and save teams
    print("\n1. Fetching ACC teams...")
    acc_teams = ss.getCollegeTeams(conference_names=['ACC'], save_to_db=True)
    print(f"   Found {len(acc_teams)} teams")
    
    # Example 2: Get and save roster
    print("\n2. Fetching Pitt men's roster for 2020...")
    try:
        pitt_roster = ss.getRoster(
            team='University of Pittsburgh',
            team_ID=405,
            gender='M',
            year=2020,
            save_to_db=True
        )
        print(f"   Found {len(pitt_roster)} swimmers")
    except Exception as e:
        print(f"   Error fetching roster: {e}")
        print("   Continuing with other examples...")
    
    # Example 3: Get and save team rankings
    print("\n3. Fetching men's team rankings for 2020...")
    try:
        rankings = ss.getTeamRankingsList('M', year=2020, save_to_db=True)
        print(f"   Found {len(rankings)} team rankings")
    except Exception as e:
        print(f"   Error fetching rankings: {e}")
        print("   Continuing with other examples...")
    
    # Example 4: Get and save team meet list
    print("\n4. Fetching Pitt meet list for 2020...")
    try:
        meets = ss.getTeamMeetList(
            team_name='University of Pittsburgh',
            team_ID=405,
            year=2020,
            save_to_db=True
        )
        print(f"   Found {len(meets)} meets")
    except Exception as e:
        print(f"   Error fetching meets: {e}")
        print("   Continuing...")
    
    print("\n" + "=" * 50)
    print("Scraping complete! Data saved to database.")
    print("\nTo query the database:")
    print("  psql -d swimscraper")
    print("\nExample queries:")
    print("  SELECT COUNT(*) FROM teams;")
    print("  SELECT COUNT(*) FROM swimmers;")
    print("  SELECT COUNT(*) FROM rosters;")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure:")
        print("  1. PostgreSQL is running")
        print("  2. Database is initialized (run: python -m SwimScraper.init_db)")
        print("  3. Database credentials are correct in database.py")
