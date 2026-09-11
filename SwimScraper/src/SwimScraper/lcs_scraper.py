"""
Long Course Season (LCS) / Long Course Meters (LCM) specific scraping functions
These functions are designed for LCS/LCM data rather than college SCY data
"""
from . import SwimScraper as ss
from . import database as db
from typing import List, Dict, Any, Optional

# Course type constants
COURSE_TYPES = {
    'SCY': 'Y',  # Short Course Yards (college)
    'SCM': 'S',  # Short Course Meters
    'LCM': 'L'   # Long Course Meters (LCS)
}

def getLCSTeamRankings(gender, season_ID=-1, year=-1, save_to_db=True):
    """
    Get team rankings for Long Course Season (LCM)
    This uses eventCourse=L parameter
    """
    # The original function already uses L, but let's make it explicit
    rankings = ss.getTeamRankingsList(gender, season_ID, year)
    
    if save_to_db and rankings:
        if season_ID == -1 and year != -1:
            season_ID = ss.getSeasonID(year)
        elif season_ID == -1:
            season_ID = 24
        
        # Save with course type indicator
        for ranking in rankings:
            ranking['course_type'] = 'LCM'
        
        db.save_team_rankings(rankings, gender, season_ID, year)
    
    return rankings

def getLCSSwimmerTimes(swimmer_ID, event_name, save_to_db=True):
    """
    Get swimmer times for Long Course events
    Event names should be LCM format (e.g., '50 L Free', '100 L Free')
    """
    # Ensure event name is LCM format
    if ' L ' not in event_name and not event_name.endswith('L'):
        # Try to convert - this is a simple approach
        event_name_lcm = event_name.replace(' Y ', ' L ').replace('Y Free', 'L Free').replace('Y Back', 'L Back').replace('Y Breast', 'L Breast').replace('Y Fly', 'L Fly').replace('Y IM', 'L IM')
    else:
        event_name_lcm = event_name
    
    times = ss.getSwimmerTimes(swimmer_ID, event_name_lcm)
    
    if save_to_db and times:
        # Add course type to each time entry
        for time_entry in times:
            time_entry['course_type'] = 'LCM'
        
        db.save_swimmer_times(swimmer_ID, times)
    
    return times

def getLCSMeetResults(meet_ID, event_name, gender, event_ID=-1, event_href='None', save_to_db=True):
    """
    Get meet results for Long Course meets
    Use this for LCS/LCM meets (typically professional/international meets)
    """
    # Use pro meet results for LCS (most LCS meets are professional/international)
    results = ss.getProMeetResults(meet_ID, event_name, gender, event_ID, event_href)
    
    if save_to_db and results:
        # Add course type
        for result in results:
            result['course_type'] = 'LCM'
        
        db.save_meet_results(results, is_pro=True)
    
    return results

def getLCSEvents():
    """Get list of all Long Course Meter events"""
    lcm_events = {}
    for event_name, event_id in ss.events.items():
        if ' L ' in event_name or event_name.endswith('L'):
            lcm_events[event_name] = event_id
    return lcm_events

def findLCSMeets(team_name='', team_ID=-1, year=-1):
    """
    Find Long Course meets for a team
    LCS meets are typically summer meets, so we look for meets in summer months
    """
    all_meets = ss.getTeamMeetList(team_name, team_ID, year=year)
    
    # Filter for likely LCS meets (summer months: June, July, August)
    lcs_meets = []
    for meet in all_meets:
        meet_date = meet.get('meet_date', '')
        # Check if meet is in summer (rough heuristic)
        if any(month in meet_date for month in ['Jun', 'Jul', 'Aug', 'June', 'July', 'August']):
            lcs_meets.append(meet)
        # Also check meet name for LCS indicators
        meet_name = meet.get('meet_name', '').lower()
        if any(indicator in meet_name for indicator in ['long course', 'lcm', 'lcs', 'summer', 'olympic', 'trials']):
            if meet not in lcs_meets:
                lcs_meets.append(meet)
    
    return lcs_meets

def fetchLCSDataForTeam(team_name, team_ID, year=2020, genders=['M', 'F'], save_to_db=True):
    """
    Fetch all LCS data for a specific team
    This includes LCS meets and swimmer times in LCM events
    """
    results = {
        'team_name': team_name,
        'team_ID': team_ID,
        'year': year,
        'lcs_meets': [],
        'lcs_rankings': {},
        'swimmers_with_lcm_times': []
    }
    
    print(f"Fetching LCS data for {team_name} ({year})...")
    
    # 1. Get LCS meets
    print("  Finding LCS meets...")
    lcs_meets = findLCSMeets(team_name=team_name, team_ID=team_ID, year=year)
    results['lcs_meets'] = lcs_meets
    print(f"    Found {len(lcs_meets)} LCS meets")
    
    if save_to_db and lcs_meets:
        db.save_meets(lcs_meets, team_ID, year)
    
    # 2. Get team rankings (LCM)
    print("  Fetching LCM team rankings...")
    for gender in genders:
        try:
            rankings = getLCSTeamRankings(gender, year=year, save_to_db=save_to_db)
            # Filter for this team
            team_rankings = [r for r in rankings if str(r.get('team_ID')) == str(team_ID)]
            results['lcs_rankings'][gender] = team_rankings
            if team_rankings:
                print(f"    {gender}: Ranked with {team_rankings[0].get('swimcloud_points')} points")
        except Exception as e:
            print(f"    Error fetching {gender} rankings: {e}")
    
    # 3. Get roster and check for LCM times
    print("  Checking swimmers for LCM times...")
    for gender in genders:
        try:
            roster = ss.getRoster(team=team_name, team_ID=team_ID, gender=gender, year=year, save_to_db=save_to_db)
            
            for swimmer in roster[:5]:  # Limit to first 5 to avoid too many requests
                swimmer_id = swimmer.get('swimmer_ID')
                try:
                    # Check for common LCM events
                    lcm_events = ['50 L Free', '100 L Free', '200 L Free', '100 L Back', '200 L Back']
                    for event in lcm_events:
                        times = getLCSSwimmerTimes(swimmer_id, event, save_to_db=save_to_db)
                        if times:
                            results['swimmers_with_lcm_times'].append({
                                'swimmer_id': swimmer_id,
                                'swimmer_name': swimmer.get('swimmer_name'),
                                'event': event,
                                'times_count': len(times)
                            })
                            break  # Found at least one LCM time
                except Exception as e:
                    continue  # Skip if error
        except Exception as e:
            print(f"    Error fetching {gender} roster: {e}")
    
    return results
