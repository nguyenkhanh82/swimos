#!/usr/bin/env python3
"""
Unified script to fetch Long Course Season (LCS) data for teams
LCS = Long Course Meters (LCM) - typically summer swimming
Supports filtering by: all teams, region, state(s), conference, division, or team names
"""
import sys
import argparse
from SwimScraper import team_filters as tf
from SwimScraper import lcs_scraper as lcs
from SwimScraper import database as db
from SwimScraper import SwimScraperDB as ss


def get_teams(filters):
    """
    Get teams based on provided filters (same logic as fetch_teams.py)
    
    Args:
        filters: dict with optional keys:
            - all: bool (fetch all teams)
            - region: str (region name)
            - states: list (state abbreviations)
            - conference: list (conference names)
            - division: list (division names)
            - team_names: list (team names)
    
    Returns:
        List of team dictionaries
    """
    if filters.get('all'):
        print("Fetching all teams...")
        teams = ss.getCollegeTeams()
        print(f"Found {len(teams)} total teams")
        return teams
    
    if filters.get('region'):
        region_name = filters['region']
        if region_name not in tf.list_regions():
            print(f"Error: Unknown region '{region_name}'")
            print(f"Available regions: {', '.join(tf.list_regions())}")
            return []
        states = tf.get_region_states(region_name)
        print(f"Region: {region_name} (States: {', '.join(states)})")
        teams = tf.get_teams_by_region(region_name)
        print(f"Found {len(teams)} teams in {region_name}")
        return teams
    
    if filters.get('states'):
        states = filters['states']
        print(f"States: {', '.join(states)}")
        teams = tf.get_teams_by_states(states)
        print(f"Found {len(teams)} teams in {', '.join(states)}")
        return teams
    
    if filters.get('conference'):
        conference_names = filters['conference']
        print(f"Conference(s): {', '.join(conference_names)}")
        teams = ss.getCollegeTeams(conference_names=conference_names)
        print(f"Found {len(teams)} teams")
        return teams
    
    if filters.get('division'):
        division_names = filters['division']
        print(f"Division(s): {', '.join(division_names)}")
        teams = ss.getCollegeTeams(division_names=division_names)
        print(f"Found {len(teams)} teams")
        return teams
    
    if filters.get('team_names'):
        team_names = filters['team_names']
        print(f"Team names: {', '.join(team_names)}")
        teams = ss.getCollegeTeams(team_names=team_names)
        print(f"Found {len(teams)} teams")
        return teams
    
    # Default: return all teams
    print("No filters specified, fetching all teams...")
    teams = ss.getCollegeTeams()
    print(f"Found {len(teams)} total teams")
    return teams


def fetch_lcs_data(teams, year=2020, genders=['M', 'F']):
    """
    Fetch LCS data for all teams
    
    Args:
        teams: List of team dictionaries
        year: Year to fetch data for
        genders: List of genders to fetch ('M', 'F')
    """
    if not teams:
        print("No teams to process")
        return
    
    print("\n" + "=" * 60)
    print("Fetching LCS (Long Course Meters) Data")
    print("=" * 60)
    print(f"Year: {year}")
    print(f"Genders: {', '.join(genders)}")
    print("=" * 60)
    
    results_summary = []
    
    for idx, team in enumerate(teams, 1):
        team_name = team['team_name']
        team_id = team['team_ID']
        
        print(f"\n[{idx}/{len(teams)}] {team_name}")
        print("-" * 60)
        
        try:
            # Fetch LCS data for this team
            results = lcs.fetchLCSDataForTeam(
                team_name=team_name,
                team_ID=team_id,
                year=year,
                genders=genders,
                save_to_db=True
            )
            
            results_summary.append({
                'team': team_name,
                'lcs_meets': len(results['lcs_meets']),
                'swimmers_with_lcm': len(results['swimmers_with_lcm_times'])
            })
            
            print(f"  ✓ Found {len(results['lcs_meets'])} LCS meets")
            print(f"  ✓ Found {len(results['swimmers_with_lcm_times'])} swimmers with LCM times")
            
        except Exception as e:
            print(f"  ✗ Error: {e}")
            results_summary.append({
                'team': team_name,
                'lcs_meets': 0,
                'swimmers_with_lcm': 0,
                'error': str(e)
            })
    
    # Summary
    print("\n" + "=" * 60)
    print("LCS Data Fetch Summary")
    print("=" * 60)
    
    total_meets = sum(r['lcs_meets'] for r in results_summary)
    total_swimmers = sum(r['swimmers_with_lcm'] for r in results_summary)
    successful = sum(1 for r in results_summary if 'error' not in r)
    failed = len(results_summary) - successful
    
    print(f"\nTotal LCS meets found: {total_meets}")
    print(f"Total swimmers with LCM times: {total_swimmers}")
    print(f"Teams: {successful} successful, {failed} with errors")
    
    if len(results_summary) <= 20:  # Only show details for small lists
        print("\nBy team:")
        for result in results_summary:
            if 'error' in result:
                print(f"  {result['team']}: ERROR - {result['error']}")
            else:
                print(f"  {result['team']}: {result['lcs_meets']} meets, {result['swimmers_with_lcm']} swimmers")


def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(
        description='Fetch Long Course Season (LCS/LCM) data for college swimming teams',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Fetch LCS data for Pacific Northwest teams
  python -m SwimScraper.scripts.fetch_lcs --region "Pacific Northwest" --year 2020
  
  # Fetch LCS data by states
  python -m SwimScraper.scripts.fetch_lcs --states WA OR ID --year 2020
  
  # Fetch LCS data by conference
  python -m SwimScraper.scripts.fetch_lcs --conference ACC --year 2020
  
  # List available regions
  python -m SwimScraper.scripts.fetch_lcs --list-regions
        """
    )
    
    # Filter options (mutually exclusive)
    filter_group = parser.add_mutually_exclusive_group()
    filter_group.add_argument('--all', action='store_true', help='Fetch all teams')
    filter_group.add_argument('--region', type=str, help='Region name (e.g., "Pacific Northwest")')
    filter_group.add_argument('--states', nargs='+', help='State abbreviations (e.g., WA OR ID)')
    filter_group.add_argument('--conference', nargs='+', help='Conference names (e.g., ACC)')
    filter_group.add_argument('--division', nargs='+', help='Division names (e.g., "Division 1")')
    filter_group.add_argument('--team-names', nargs='+', help='Specific team names')
    
    # Action options
    parser.add_argument('--year', type=int, default=2020, help='Year to fetch data for (default: 2020)')
    parser.add_argument('--genders', nargs='+', choices=['M', 'F'], default=['M', 'F'], 
                       help='Genders to fetch (default: M F)')
    parser.add_argument('--list-regions', action='store_true', help='List all available regions')
    
    args = parser.parse_args()
    
    # List regions if requested
    if args.list_regions:
        print("Available regions:")
        print("=" * 60)
        for region in tf.list_regions():
            states = tf.get_region_states(region)
            print(f"  {region}: {', '.join(states)}")
        return
    
    # Build filters dict
    filters = {}
    if args.all:
        filters['all'] = True
    elif args.region:
        filters['region'] = args.region
    elif args.states:
        filters['states'] = [s.upper() for s in args.states]
    elif args.conference:
        filters['conference'] = args.conference
    elif args.division:
        filters['division'] = args.division
    elif args.team_names:
        filters['team_names'] = args.team_names
    
    # Get teams
    print("SwimScraper - LCS Data Fetcher")
    print("=" * 60)
    teams = get_teams(filters)
    
    if not teams:
        print("\nNo teams found matching the criteria.")
        return
    
    # Save teams to database
    db.save_teams(teams)
    print(f"\n✓ Saved {len(teams)} teams to database")
    
    # Fetch LCS data
    fetch_lcs_data(teams, year=args.year, genders=args.genders)
    
    print("\n" + "=" * 60)
    print("LCS data saved to database!")
    print("\nTo query LCS data:")
    print("  psql -d swimscraper")
    print("\nExample queries:")
    print("  -- All LCM swimmer times")
    print("  SELECT * FROM swimmer_times WHERE course_type = 'LCM';")
    print("\n  -- LCS meet results")
    print("  SELECT * FROM pro_meet_results WHERE course_type = 'LCM';")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nScraping interrupted by user.")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
