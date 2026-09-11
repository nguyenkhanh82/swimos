"""
Utility and helper functions for SwimScraper
"""
from .config import teams, EVENTS, US_STATES

def clean_name(web_name):
    """Convert name from (last, first) to (first last)"""
    name_list = web_name.split(', ')
    if len(name_list) < 2:
        return web_name
    last_name = name_list[0]
    first_name = name_list[1]
    return first_name + ' ' + last_name

# Backward compatibility
cleanName = clean_name

def get_team_id(team_name):
    """Get team ID for a given team name"""
    for index, row in teams.iterrows():
        if row['team_name'] == team_name:
            return row['team_ID']
    return -1

# Backward compatibility
getTeamID = get_team_id

def get_team_name(team_id):
    """Get team name for a given team ID"""
    for index, row in teams.iterrows():
        if row['team_ID'] == team_id:
            return row['team_name']
    return ''

# Backward compatibility
getTeamName = get_team_name

def get_season_id(year):
    """Get season ID for a given year"""
    return year - 1996

# Backward compatibility
getSeasonID = get_season_id

def get_year(season_id):
    """Get year for a given season ID"""
    return season_id + 1996

# Backward compatibility
getYear = get_year

def get_event_name(event_id):
    """Get event name for a given event ID"""
    for event_name, eid in EVENTS.items():
        if str(eid) == str(event_id):
            return event_name
    return ''

# Backward compatibility
getEventName = get_event_name

def get_event_id(event_name):
    """Get event ID for a given event name"""
    return EVENTS.get(event_name)

# Backward compatibility
getEventID = get_event_id

def get_state(hometown):
    """Extract state or country from hometown string"""
    home = hometown.split(',')[-1].strip()
    if home.isalpha():
        return home
    return 'NONE'

# Backward compatibility
getState = get_state

def get_city(hometown):
    """Extract city from hometown string"""
    home = hometown.split(',')
    if len(home) > 1:
        home.pop()  # Remove state/country
        city = ' '.join([c.strip() for c in home])
        return city
    return hometown

# Backward compatibility
getCity = get_city

def convert_time(display_time):
    """Convert time from minutes:seconds (1:53.8) to seconds (113.8)"""
    if ':' in display_time:
        time_array = display_time.split(':')
        seconds = float(time_array[0]) * 60
        seconds += float(time_array[1])
        return seconds
    elif display_time.isalpha():
        return None
    else:
        return float(display_time)

# Backward compatibility
convertTime = convert_time

def get_indexes(data):
    """
    Get column indexes from HTML table header
    Returns dict with meet_name_index, date_index, additional_info_index
    """
    meet_name_index = -1
    date_index = -1
    additional_info_index = -1
    
    for i, td in enumerate(data):
        if td.text.strip() == 'Meet':
            meet_name_index = i
        elif td.text.strip() == 'Date':
            date_index = i
        elif td.text.strip() == '' and td.has_attr('class') and 'c-table-clean__col-fit' in td['class']:
            additional_info_index = i
    
    return {
        'meet_name_index': meet_name_index,
        'date_index': date_index,
        'additional_info_index': additional_info_index
    }

# Backward compatibility
getIndexes = get_indexes
