#!/usr/bin/env python3
"""
Unified script to fetch teams and their data
Supports filtering by: all teams, region, state(s), conference, division, or team names
Supports both college teams and club teams
"""
import sys
import argparse
from SwimScraper import SwimScraperDB as ss
from SwimScraper import team_filters as tf
from SwimScraper import database as db
from SwimScraper.scrapers import clubs


def get_teams(filters):
    """
    Get teams based on provided filters
    
    Args:
        filters: dict with optional keys:
            - all: bool (fetch all teams)
            - region: str (region name)
            - states: list (state abbreviations)
            - conference: list (conference names)
            - division: list (division names)
            - team_names: list (team names)
            - team_type: str ('college', 'club', or 'all')
            - lsc_code: str (LSC code for club teams)
    
    Returns:
        List of team dictionaries
    """
    team_type = filters.get('team_type', 'all')
    include_college = team_type in ['college', 'all']
    include_club = team_type in ['club', 'all']
    
    all_teams = []
    
    # Fetch college teams if requested
    if include_college:
        if filters.get('all'):
            print("Fetching all college teams...")
            college_teams = ss.getCollegeTeams(save_to_db=False)  # Don't save yet, we'll save all together
            print(f"Found {len(college_teams)} college teams")
            all_teams.extend(college_teams)
        elif filters.get('region'):
            region_name = filters['region']
            if region_name not in tf.list_regions():
                print(f"Error: Unknown region '{region_name}'")
                print(f"Available regions: {', '.join(tf.list_regions())}")
                return []
            states = tf.get_region_states(region_name)
            print(f"Region: {region_name} (States: {', '.join(states)})")
            college_teams = tf.get_teams_by_region(region_name)
            print(f"Found {len(college_teams)} college teams in {region_name}")
            all_teams.extend(college_teams)
        elif filters.get('states'):
            states = filters['states']
            print(f"States: {', '.join(states)}")
            college_teams = tf.get_teams_by_states(states)
            print(f"Found {len(college_teams)} college teams in {', '.join(states)}")
            all_teams.extend(college_teams)
        elif filters.get('conference'):
            conference_names = filters['conference']
            print(f"Conference(s): {', '.join(conference_names)}")
            college_teams = ss.getCollegeTeams(conference_names=conference_names)
            print(f"Found {len(college_teams)} college teams")
            all_teams.extend(college_teams)
        elif filters.get('division'):
            division_names = filters['division']
            print(f"Division(s): {', '.join(division_names)}")
            college_teams = ss.getCollegeTeams(division_names=division_names)
            print(f"Found {len(college_teams)} college teams")
            all_teams.extend(college_teams)
        elif filters.get('team_names'):
            team_names = filters['team_names']
            print(f"Team names: {', '.join(team_names)}")
            college_teams = ss.getCollegeTeams(team_names=team_names)
            print(f"Found {len(college_teams)} college teams")
            all_teams.extend(college_teams)
    
    # Fetch club teams if requested
    if include_club:
        if filters.get('lsc_code'):
            # Fetch by specific LSC code
            lsc_code = filters['lsc_code']
            print(f"Fetching club teams for LSC: {lsc_code}...")
            club_teams = clubs.get_club_teams_by_lsc(lsc_code, year=filters.get('year', -1))
            print(f"Found {len(club_teams)} club teams")
            all_teams.extend(club_teams)
        elif filters.get('region'):
            # Fetch club teams for the region
            region_name = filters['region']
            print(f"Fetching club teams for region: {region_name}...")
            club_teams = clubs.get_club_teams_by_region(region_name, year=filters.get('year', -1))
            print(f"Found {len(club_teams)} club teams")
            all_teams.extend(club_teams)
        elif filters.get('all'):
            # Fetch all club teams (this will take a while!)
            print("Fetching all club teams (this may take a while)...")
            club_teams = clubs.get_all_club_teams(year=filters.get('year', -1))
            print(f"Found {len(club_teams)} club teams")
            all_teams.extend(club_teams)
    
    if not all_teams and not filters.get('all'):
        # Default: return all college teams
        print("No filters specified, fetching all college teams...")
        all_teams = ss.getCollegeTeams(save_to_db=False)
        print(f"Found {len(all_teams)} total teams")
    
    return all_teams
    


def display_teams(teams):
    """Display teams grouped by state"""
    if not teams:
        return
    
    print("\n" + "=" * 60)
    print(f"Teams Found: {len(teams)}")
    print("=" * 60)
    
    # Group by state
    by_state = {}
    for team in teams:
        state = team.get('team_state') or team.get('region_code') or 'Unknown'
        # Handle None values
        if state is None:
            state = 'Unknown'
        state = str(state)  # Ensure it's a string for sorting
        if state not in by_state:
            by_state[state] = []
        by_state[state].append(team)
    
    # Print teams by state
    for state in sorted(by_state.keys(), key=lambda x: str(x)):
        print(f"\n{state} ({len(by_state[state])} teams):")
        for team in sorted(by_state[state], key=lambda x: x['team_name']):
            print(f"  - {team['team_name']} (ID: {team['team_ID']})")


def fetch_team_data(teams, year=2020, genders=['M', 'F']):
    """
    Fetch rosters and meet lists for all teams
    
    Args:
        teams: List of team dictionaries
        year: Year to fetch data for
        genders: List of genders to fetch ('M', 'F')
    """
    if not teams:
        print("No teams to process")
        return
    
    print("\n" + "=" * 60)
    print("Fetching Team Data")
    print("=" * 60)
    print(f"Year: {year}")
    print(f"Genders: {', '.join(genders)}")
    print("=" * 60)
    
    total_teams = len(teams)
    successful = 0
    failed = 0
    
    for idx, team in enumerate(teams, 1):
        team_name = team['team_name']
        team_id = team['team_ID']
        
        print(f"\n[{idx}/{total_teams}] Processing: {team_name} (ID: {team_id})")
        print("-" * 60)
        
        team_success = True
        for gender in genders:
            try:
                # Fetch roster
                print(f"  Fetching {gender} roster for {year}...")
                roster = ss.getRoster(
                    team=team_name,
                    team_ID=team_id,
                    gender=gender,
                    year=year,
                    save_to_db=True
                )
                print(f"    Found {len(roster)} swimmers")
                
                # Fetch meet list
                print(f"  Fetching {gender} meet list for {year}...")
                meets = ss.getTeamMeetList(
                    team_name=team_name,
                    team_ID=team_id,
                    year=year,
                    save_to_db=True
                )
                print(f"    Found {len(meets)} meets")
                
            except Exception as e:
                print(f"    Error: {e}")
                team_success = False
                continue
        
        if team_success:
            successful += 1
            print(f"  ✓ Completed {team_name}")
        else:
            failed += 1
            print(f"  ⚠ Completed {team_name} (with errors)")
    
    print("\n" + "=" * 60)
    print(f"Summary: {successful} successful, {failed} with errors")
    print("=" * 60)


def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(
        description='Fetch college swimming teams and their data',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Fetch all teams (college and club)
  python -m SwimScraper.scripts.fetch_teams --all --fetch --year 2020
  
  # Fetch Pacific Northwest teams (college and club)
  python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --fetch
  
  # Fetch only club teams for Pacific Northwest
  python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --team-type club --fetch
  
  # Fetch only college teams
  python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --team-type college --fetch
  
  # Fetch club teams by LSC code
  python -m SwimScraper.scripts.fetch_teams --lsc-code PN --fetch
  
  # Fetch teams by states
  python -m SwimScraper.scripts.fetch_teams --states WA OR ID --fetch
  
  # Fetch teams by conference
  python -m SwimScraper.scripts.fetch_teams --conference ACC --fetch
  
  # Fetch teams by division
  python -m SwimScraper.scripts.fetch_teams --division "Division 1" --fetch
  
  # List available regions
  python -m SwimScraper.scripts.fetch_teams --list-regions
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
    filter_group.add_argument('--lsc-code', type=str, help='LSC code for club teams (e.g., PN for Pacific Northwest)')
    
    # Team type option
    parser.add_argument('--team-type', choices=['college', 'club', 'prep', 'mss', 'ccs', 'sls', 'all'], default='all',
                       help='Type of teams to fetch: college, club, prep (high school), mss (middle school), ccs (college club), sls (summer/rec), or all (default: all)')
    
    # Organization type option (alias for team-type)
    parser.add_argument('--org-type', choices=['college', 'club', 'prep', 'mss', 'ccs', 'sls', 'all'], 
                       help='Organization type (alias for --team-type)')
    
    # Action options
    parser.add_argument('--fetch', action='store_true', help='Fetch rosters and meets (not just teams)')
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
    org_type = args.org_type if args.org_type else args.team_type
    filters = {
        'team_type': org_type,
        'organization_type': org_type,
        'year': args.year
    }
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
    elif args.lsc_code:
        filters['lsc_code'] = args.lsc_code.upper()
    
    # Get teams
    print("SwimScraper - Team Data Fetcher")
    print("=" * 60)
    teams = get_teams(filters)
    
    if not teams:
        print("\nNo teams found matching the criteria.")
        return
    
    # Save teams to database
    db.save_teams(teams)
    print(f"\n✓ Saved {len(teams)} teams to database")
    
    # Display teams
    display_teams(teams)
    
    # Fetch data if requested
    if args.fetch:
        fetch_team_data(teams, year=args.year, genders=args.genders)
        
        print("\n" + "=" * 60)
        print("Scraping complete!")
        print(f"Data for {len(teams)} teams has been saved to the database.")
        print("\nTo query the database:")
        print("  psql -d swimscraper")
    else:
        print("\n" + "=" * 60)
        print("Teams saved. To fetch rosters and meets, use --fetch flag:")
        print(f"  python -m SwimScraper.scripts.fetch_teams {' '.join(sys.argv[1:])} --fetch")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nScraping interrupted by user.")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
