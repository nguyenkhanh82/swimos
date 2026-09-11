#!/usr/bin/env python3
"""
Fetch all swimmers' times for teams
For each team, gets roster, then for each swimmer gets all events and times
"""
import argparse
import sys
from typing import List, Dict, Any

from .. import SwimScraperDB as ss
from ..scrapers import clubs
from .. import database as db


def fetch_swimmer_times_for_team(team_name, team_id, genders=['M', 'F'], year=-1, save_to_db=True):
    """
    Fetch all swimmers' times for a specific team
    
    Args:
        team_name: Team name
        team_id: Team ID
        genders: List of genders to fetch ('M', 'F', or both)
        year: Year to fetch (optional, -1 for current)
        save_to_db: Whether to save to database
    
    Returns:
        Dictionary with summary of what was fetched
    """
    print(f"\n{'='*60}")
    print(f"Fetching swimmer times for: {team_name} (ID: {team_id})")
    print(f"{'='*60}")
    
    summary = {
        'team_name': team_name,
        'team_id': team_id,
        'swimmers_processed': 0,
        'events_found': 0,
        'times_found': 0,
        'errors': []
    }
    
    # Get roster for each gender
    all_roster = []
    for gender in genders:
        print(f"\n  Fetching {gender} roster...")
        try:
            roster = ss.getRoster(team_name, gender, team_ID=team_id, year=year, save_to_db=save_to_db)
            if roster:
                print(f"    Found {len(roster)} swimmers")
                all_roster.extend(roster)
            else:
                print(f"    No roster found for {gender}")
        except Exception as e:
            error_msg = f"Error fetching {gender} roster: {e}"
            print(f"    {error_msg}")
            summary['errors'].append(error_msg)
            continue
    
    if not all_roster:
        print(f"\n  No swimmers found for {team_name}")
        return summary
    
    print(f"\n  Total swimmers: {len(all_roster)}")
    print(f"  Fetching events and times for each swimmer...")
    
    # For each swimmer, get their events and times
    for i, swimmer in enumerate(all_roster, 1):
        swimmer_id = swimmer.get('swimmer_ID')
        swimmer_name = swimmer.get('swimmer_name', 'Unknown')
        
        if not swimmer_id:
            continue
        
        print(f"\n    [{i}/{len(all_roster)}] {swimmer_name} (ID: {swimmer_id})")
        
        try:
            # Get all events for this swimmer
            events = ss.getSwimmerEvents(swimmer_id, save_to_db=save_to_db)
            
            if not events:
                print(f"      No events found")
                continue
            
            print(f"      Found {len(events)} events")
            summary['events_found'] += len(events)
            
            # Get times for each event
            for event_name in events:
                try:
                    times = ss.getSwimmerTimes(swimmer_id, event_name, save_to_db=save_to_db)
                    if times:
                        summary['times_found'] += len(times)
                        print(f"        {event_name}: {len(times)} times")
                except Exception as e:
                    error_msg = f"Error fetching times for {swimmer_name} - {event_name}: {e}"
                    print(f"        Error: {e}")
                    summary['errors'].append(error_msg)
            
            summary['swimmers_processed'] += 1
            
        except Exception as e:
            error_msg = f"Error processing swimmer {swimmer_name} (ID: {swimmer_id}): {e}"
            print(f"      Error: {e}")
            summary['errors'].append(error_msg)
            continue
    
    print(f"\n  Summary for {team_name}:")
    print(f"    Swimmers processed: {summary['swimmers_processed']}")
    print(f"    Events found: {summary['events_found']}")
    print(f"    Times found: {summary['times_found']}")
    if summary['errors']:
        print(f"    Errors: {len(summary['errors'])}")
    
    return summary


def fetch_swimmer_times_for_swimmer(swimmer_id, save_to_db=True):
    """
    Fetch all events and times for a single swimmer
    
    Args:
        swimmer_id: Swimmer ID
        save_to_db: Whether to save to database
    
    Returns:
        Dictionary with summary of what was fetched
    """
    print(f"\n{'='*60}")
    print(f"Fetching times for swimmer ID: {swimmer_id}")
    print(f"{'='*60}")
    
    summary = {
        'swimmer_id': swimmer_id,
        'events_found': 0,
        'times_found': 0,
        'errors': []
    }
    
    try:
        # Get all events for this swimmer
        print(f"\n  Fetching events...")
        events = ss.getSwimmerEvents(swimmer_id, save_to_db=save_to_db)
        
        if not events:
            print(f"  No events found for swimmer {swimmer_id}")
            return summary
        
        print(f"  Found {len(events)} events")
        summary['events_found'] = len(events)
        
        # Get times for each event
        print(f"\n  Fetching times for each event...")
        for i, event_name in enumerate(events, 1):
            print(f"    [{i}/{len(events)}] {event_name}")
            try:
                times = ss.getSwimmerTimes(swimmer_id, event_name, save_to_db=save_to_db)
                if times:
                    summary['times_found'] += len(times)
                    print(f"      Found {len(times)} times")
                else:
                    print(f"      No times found")
            except Exception as e:
                error_msg = f"Error fetching times for {event_name}: {e}"
                print(f"      Error: {e}")
                summary['errors'].append(error_msg)
        
        print(f"\n  Summary:")
        print(f"    Events found: {summary['events_found']}")
        print(f"    Times found: {summary['times_found']}")
        if summary['errors']:
            print(f"    Errors: {len(summary['errors'])}")
        
    except Exception as e:
        error_msg = f"Error processing swimmer {swimmer_id}: {e}"
        print(f"  Error: {e}")
        summary['errors'].append(error_msg)
    
    return summary


def fetch_swimmer_times_for_club_teams(lsc_code=None, region=None, team_ids=None, team_names=None, 
                                       genders=['M', 'F'], year=-1, save_to_db=True):
    """
    Fetch all swimmers' times for club teams
    
    Args:
        lsc_code: LSC code (e.g., 'PN')
        region: Region name (e.g., 'Pacific Northwest')
        team_ids: List of specific team IDs
        team_names: List of specific team names
        genders: List of genders to fetch
        year: Year to fetch
        save_to_db: Whether to save to database
    
    Returns:
        List of summary dictionaries
    """
    # Get teams
    teams = []
    
    if team_ids or team_names:
        # Fetch specific teams
        if team_ids:
            from ..database import get_connection
            conn = get_connection()
            cursor = conn.cursor()
            for team_id in team_ids:
                cursor.execute("SELECT team_name, team_id FROM teams WHERE team_id = %s", (team_id,))
                result = cursor.fetchone()
                if result:
                    teams.append({'team_name': result[0], 'team_ID': result[1]})
            cursor.close()
            conn.close()
        
        if team_names:
            from ..database import get_connection
            conn = get_connection()
            cursor = conn.cursor()
            for team_name in team_names:
                cursor.execute("SELECT team_name, team_id FROM teams WHERE team_name = %s", (team_name,))
                result = cursor.fetchone()
                if result:
                    teams.append({'team_name': result[0], 'team_ID': result[1]})
            cursor.close()
            conn.close()
    elif lsc_code:
        # Fetch teams by LSC
        teams = clubs.get_club_teams_by_lsc(lsc_code, year=year)
    elif region:
        # Fetch teams by region
        teams = clubs.get_club_teams_by_region(region, year=year)
    else:
        print("Error: Must specify lsc_code, region, team_ids, or team_names")
        return []
    
    if not teams:
        print("No teams found")
        return []
    
    print(f"\n{'='*60}")
    print(f"Fetching swimmer times for {len(teams)} club teams")
    print(f"{'='*60}")
    
    summaries = []
    for i, team in enumerate(teams, 1):
        team_name = team.get('team_name')
        team_id = team.get('team_ID')
        
        if not team_name or not team_id:
            continue
        
        print(f"\n\n[{i}/{len(teams)}] Processing team: {team_name}")
        
        summary = fetch_swimmer_times_for_team(
            team_name, team_id, 
            genders=genders, 
            year=year, 
            save_to_db=save_to_db
        )
        summaries.append(summary)
    
    # Print overall summary
    print(f"\n\n{'='*60}")
    print(f"OVERALL SUMMARY")
    print(f"{'='*60}")
    total_swimmers = sum(s['swimmers_processed'] for s in summaries)
    total_events = sum(s['events_found'] for s in summaries)
    total_times = sum(s['times_found'] for s in summaries)
    total_errors = sum(len(s['errors']) for s in summaries)
    
    print(f"Teams processed: {len(summaries)}")
    print(f"Total swimmers processed: {total_swimmers}")
    print(f"Total events found: {total_events}")
    print(f"Total times found: {total_times}")
    if total_errors > 0:
        print(f"Total errors: {total_errors}")
    
    return summaries


def main():
    parser = argparse.ArgumentParser(
        description='Fetch all swimmers\' times for club teams',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Fetch times for a single swimmer
  python -m SwimScraper.scripts.fetch_swimmer_times --swimmer-id 3397927
  
  # Fetch times for all teams in Pacific Northwest LSC
  python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN
  
  # Fetch times for specific teams
  python -m SwimScraper.scripts.fetch_swimmer_times --team-ids 7992 8019
  
  # Fetch only women's times
  python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN --genders F
  
  # Fetch times for a specific year
  python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN --year 2023
        """
    )
    
    parser.add_argument('--swimmer-id', type=int, help='Fetch times for a single swimmer by ID')
    parser.add_argument('--lsc-code', type=str, help='LSC code (e.g., PN)')
    parser.add_argument('--region', type=str, help='Region name (e.g., "Pacific Northwest")')
    parser.add_argument('--team-ids', type=int, nargs='+', help='Specific team IDs')
    parser.add_argument('--team-names', type=str, nargs='+', help='Specific team names')
    parser.add_argument('--genders', type=str, nargs='+', choices=['M', 'F'], default=['M', 'F'],
                       help='Genders to fetch (default: both M and F)')
    parser.add_argument('--year', type=int, default=-1, help='Year to fetch (default: current)')
    parser.add_argument('--no-save', action='store_true', help='Don\'t save to database (for testing)')
    
    args = parser.parse_args()
    
    # If swimmer-id is specified, fetch for that swimmer only
    if args.swimmer_id:
        try:
            summary = fetch_swimmer_times_for_swimmer(
                args.swimmer_id,
                save_to_db=not args.no_save
            )
            
            if summary['times_found'] > 0:
                print(f"\n✓ Completed fetching times for swimmer {args.swimmer_id}")
            else:
                print(f"\n✗ No times found for swimmer {args.swimmer_id}")
                sys.exit(1)
            
        except KeyboardInterrupt:
            print("\n\nInterrupted by user")
            sys.exit(1)
        except Exception as e:
            print(f"\nError: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)
        
        return
    
    if not any([args.lsc_code, args.region, args.team_ids, args.team_names]):
        parser.error("Must specify one of: --swimmer-id, --lsc-code, --region, --team-ids, or --team-names")
    
    try:
        summaries = fetch_swimmer_times_for_club_teams(
            lsc_code=args.lsc_code,
            region=args.region,
            team_ids=args.team_ids,
            team_names=args.team_names,
            genders=args.genders,
            year=args.year,
            save_to_db=not args.no_save
        )
        
        if summaries:
            print(f"\n✓ Completed fetching swimmer times for {len(summaries)} teams")
        else:
            print("\n✗ No teams processed")
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
