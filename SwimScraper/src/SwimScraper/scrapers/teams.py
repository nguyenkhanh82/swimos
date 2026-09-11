"""
Team-related scraping functions
"""
import requests
import time as _time
from bs4 import BeautifulSoup as bs
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException, StaleElementReferenceException
from requests.exceptions import RequestException, Timeout

from ..config import teams, REQUEST_HEADERS, DEFAULT_SEASON_ID
from ..utils import (
    getTeamID, getTeamName, getSeasonID, getYear,
    getState, getCity, cleanName
)
# Note: getPowerIndex imported dynamically in getRoster to avoid circular import


def getCollegeTeams(team_names=['NONE'], conference_names=['NONE'], division_names=['NONE']):
    """
    Get college teams by name, conference, or division
    
    Args:
        team_names: List of team names
        conference_names: List of conference names
        division_names: List of division names
    
    Returns:
        List of team dictionaries with organization_type='college'
    """
    team_df = teams.copy()
    
    if team_names != ['NONE']:
        team_df = team_df[team_df['team_name'].isin(team_names)].reset_index(drop=True)
    elif division_names != ['NONE']:
        team_df = team_df[team_df['team_division'].isin(division_names)].reset_index(drop=True)
    elif conference_names != ['NONE']:
        team_df = team_df[team_df['team_conference'].isin(conference_names)].reset_index(drop=True)
    
    # Convert to dict and add organization_type
    team_list = team_df.to_dict('records')
    for team in team_list:
        team['organization_type'] = 'college'
        team['team_type'] = 'college'  # For backward compatibility
    
    return team_list


def getTeamRankingsList(gender, season_ID=-1, year=-1):
    """
    Get team rankings list
    
    Args:
        gender: 'M' or 'F'
        season_ID: Season ID (optional)
        year: Year (optional)
    
    Returns:
        List of team ranking dictionaries
    """
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    driver = webdriver.Chrome(options=chrome_options)
    
    teams_list = []
    
    if gender not in ['M', 'F']:
        print('ERROR: need to input either M or F for gender')
        driver.close()
        return teams_list
    
    if year != -1:
        season_ID = getSeasonID(year)
    elif season_ID == -1:
        season_ID = DEFAULT_SEASON_ID
    
    page_url = f'https://swimcloud.com/team/rankings/?eventCourse=L&gender={gender}&page=1&region&seasonId={season_ID}'
    
    try:
        driver.get(page_url)
        _time.sleep(3)
        
        html = driver.page_source
        soup = bs(html, 'html.parser')
        
        teams_table = soup.find('table', attrs={'class': 'c-table-clean'})
        if teams_table:
            teams_rows = teams_table.find('tbody').find_all('tr')
            
            for team_row in teams_rows:
                data = team_row.find_all('td')
                if len(data) >= 3:
                    team_name = data[1].find('strong').text.strip()
                    team_link = data[1].find('a')
                    team_ID = team_link['href'].split('/')[-1] if team_link else None
                    swimcloud_points = data[2].find('a').text.strip() if data[2].find('a') else ''
                    
                    teams_list.append({
                        'team_name': team_name,
                        'team_ID': team_ID,
                        'swimcloud_points': swimcloud_points
                    })
    finally:
        driver.close()
    
    return teams_list


def getRoster(team, gender, team_ID=-1, season_ID=-1, year=-1, pro=False):
    """
    Get team roster
    
    Args:
        team: Team name
        gender: 'M' or 'F'
        team_ID: Team ID (optional)
        season_ID: Season ID (optional)
        year: Year (optional)
        pro: Whether professional team (default: False)
    
    Returns:
        List of swimmer dictionaries
    """
    roster = []
    
    if gender not in ['M', 'F']:
        print('ERROR: need to input either M or F for gender')
        return roster
    
    # Get team ID
    if team_ID != -1:
        team_number = team_ID
        if not team:
            team = getTeamName(team_ID)
    else:
        team_number = getTeamID(team)
        if team_number == -1:
            print(f'ERROR: Team "{team}" not found')
            return roster
    
    # Get season ID
    if year != -1:
        season_ID = getSeasonID(year)
    elif season_ID == -1:
        season_ID = DEFAULT_SEASON_ID
    
    roster_url = f'https://www.swimcloud.com/team/{team_number}/roster/?page=1&gender={gender}&season_id={season_ID}'
    
    try:
        url = requests.get(roster_url, headers=REQUEST_HEADERS, timeout=10)
        url.encoding = 'utf-8'
        soup = bs(url.text, 'html.parser')
        
        # Check if page indicates no roster/team doesn't exist
        page_text = soup.get_text().lower()
        if '404' in page_text or 'not found' in page_text or 'page not found' in page_text:
            print(f'  Team {team} (ID: {team_number}) not found or no roster available for {gender}')
            return roster
        
        # Try multiple possible table class names
        table = soup.find('table', attrs={'class': 'c-table-clean c-table-clean--middle table table-hover'})
        if not table:
            # Try alternative table classes
            table = soup.find('table', attrs={'class': 'c-table-clean'})
        if not table:
            # Try any table
            table = soup.find('table')
        
        if not table:
            # Check if page says no roster available
            if 'no roster' in page_text or 'no swimmers' in page_text or 'empty' in page_text:
                print(f'  No roster available for {team} ({gender})')
                return roster
            # Check if it's a valid team page but just no roster for this season/gender
            if 'roster' in page_text or 'team' in page_text:
                print(f'  No roster data found for {team} ({gender}) in season {season_ID}')
                return roster
            print(f'  Warning: Could not find roster table for {team} ({gender}) - page structure may have changed')
            return roster
        
        rows = table.find_all('tr')
        if len(rows) <= 1:  # Only header or empty
            print(f'  No swimmers found for {team} ({gender})')
            return roster
        
        rows = rows[1:]  # Skip header
        
        for row in rows:
            try:
                swimmer_link = row.find('a')
                if not swimmer_link:
                    continue
                
                swimmer_name = cleanName(swimmer_link.text.strip())
                id_links = row.find_all('a')
                
                if not id_links or 'href' not in id_links[0].attrs:
                    continue
                
                swimmer_ID = id_links[0]['href'].split('/')[-1]
                cells = row.find_all('td')
                
                if len(cells) < 3:
                    state = 'NONE'
                    city = 'NONE'
                    grade = 'NONE' if not pro else 'None'
                else:
                    state = getState(cells[2].text.strip())
                    city = getCity(cells[2].text.strip())
                    if not pro:
                        grade = cells[3].text.strip() if len(cells) >= 4 else 'NONE'
                    else:
                        grade = 'None'
                
                # Get power index for college swimmers
                if not pro:
                    try:
                        # Import here to avoid circular dependency
                        from .swimmers import getPowerIndex
                        HS_power_index = getPowerIndex(swimmer_ID)
                    except Exception:
                        HS_power_index = -1
                else:
                    HS_power_index = -1
                
                roster.append({
                    'swimmer_name': swimmer_name,
                    'swimmer_ID': swimmer_ID,
                    'team_name': team,
                    'team_ID': team_number,
                    'grade': grade,
                    'hometown_state': state,
                    'hometown_city': city,
                    'HS_power_index': HS_power_index
                })
            except (IndexError, AttributeError, KeyError) as e:
                # Silently skip malformed rows - they're common in roster tables
                # Only log if it's a truly unexpected error
                continue
                
    except requests.exceptions.RequestException as e:
        print(f'  Error fetching roster URL: {e}')
        return roster
    except Exception as e:
        print(f'  Unexpected error fetching roster: {e}')
        return roster
                
    except Exception as e:
        print(f'ERROR fetching roster: {e}')
        raise
    
    return roster


def getTeamMeetList(team_name='', team_ID=-1, season_ID=-1, year=-1):
    """
    Get list of meets for a team
    
    Args:
        team_name: Team name (optional)
        team_ID: Team ID (optional)
        season_ID: Season ID (optional)
        year: Year (optional)
    
    Returns:
        List of meet dictionaries
    """
    meet_list = []
    
    # Get team ID
    if team_name:
        team_number = getTeamID(team_name)
    elif team_ID != -1:
        team_number = team_ID
    else:
        print('ERROR: Must provide either team_name or team_ID')
        return meet_list
    
    # Get year
    if season_ID != -1:
        year = getYear(season_ID)
    elif year == -1:
        year = 2021  # Default
    
    team_url = f'https://www.swimcloud.com/team/{team_number}/results/?page=1&name=&meettype=&year={year}'
    
    try:
        url = requests.get(team_url, headers=REQUEST_HEADERS)
        url.encoding = 'utf-8'
        soup = bs(url.text, 'html.parser')
        
        meets_section = soup.find('section', attrs={'class': 'c-list-grid'})
        if not meets_section:
            print('ERROR: Could not find meets section')
            return meet_list
        
        meets = meets_section.find_all('a', attrs={'class': 'c-list-grid__item'})
        
        for meet in meets:
            try:
                meet_ID = meet['href'].split('/')[-1]
                meet_name = meet.find('article').find('h3').text.strip()
                meet_date = meet.find('time').text.strip()
                meet_location = meet.find_all('li')[-1].text.strip() if meet.find_all('li') else ''
                
                meet_list.append({
                    'team_ID': team_number,
                    'meet_ID': meet_ID,
                    'meet_name': meet_name,
                    'meet_date': meet_date,
                    'meet_location': meet_location
                })
            except (AttributeError, KeyError) as e:
                print(f"Warning: Skipping meet due to error: {e}")
                continue
                
    except Exception as e:
        print(f'ERROR fetching team meets: {e}')
        raise
    
    return meet_list
