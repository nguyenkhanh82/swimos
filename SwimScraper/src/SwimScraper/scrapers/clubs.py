"""
Club team scraping functions
Fetches club teams from swimcloud.com by LSC (Local Swimming Committee) region
"""
import requests
import time as _time
from bs4 import BeautifulSoup as bs
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException, TimeoutException
from urllib.parse import urlencode, urlparse, parse_qs

from ..config import REQUEST_HEADERS
from ..utils import getSeasonID, getYear

# LSC (Local Swimming Committee) codes mapped to regions
# These are USA Swimming's regional organizations
LSC_CODES = {
    'PN': 'Pacific Northwest',  # Washington, Oregon, Idaho
    'OR': 'Oregon',
    'CA': 'Southern California',
    'PC': 'Pacific Swimming',  # Northern California
    'SN': 'Sierra Nevada',
    'SI': 'San Diego-Imperial',
    'CC': 'Central California',
    'IE': 'Inland Empire',
    'AZ': 'Arizona',
    'UT': 'Utah',
    'CO': 'Colorado',
    'WY': 'Wyoming',
    'MT': 'Montana',
    'ID': 'Idaho',  # Note: Some parts of ID might be in PN LSC
    'AK': 'Alaska',
    'HI': 'Hawaiian',
    'WA': 'Washington',  # Note: WA is primarily in PN LSC
    # Add more as needed
}

# Reverse mapping: region name to LSC codes
REGION_TO_LSC = {
    'Pacific Northwest': ['PN'],
    'West Coast': ['PN', 'OR', 'CA', 'PC', 'SN', 'SI', 'CC', 'IE', 'AZ', 'UT', 'CO', 'WY', 'MT', 'ID', 'AK', 'HI'],
    # Add more mappings as needed
}


def get_club_teams_from_url(url, save_to_db=False):
    """
    Extract club teams from a specific SwimCloud URL with query parameters
    
    Args:
        url: Full SwimCloud URL with query parameters (e.g., teams page with filters)
        save_to_db: Whether to save to database (requires database module)
    
    Returns:
        List of team dictionaries with:
        - team_name: Name of the club team
        - team_ID: SwimCloud team ID
        - team_type: 'club'
        - organization_type: 'club'
        - lsc_code: LSC code (extracted from URL)
        - additional metadata from query parameters
    """
    teams = []
    driver = None
    use_selenium = False
    
    # Parse URL to extract parameters
    parsed_url = urlparse(url)
    query_params = parse_qs(parsed_url.query)
    
    # Extract LSC code from URL path
    path_parts = parsed_url.path.split('/')
    lsc_code = None
    if 'lsc' in path_parts:
        lsc_idx = path_parts.index('lsc')
        if lsc_idx + 1 < len(path_parts):
            lsc_code = path_parts[lsc_idx + 1]
    
    # Extract metadata from query parameters
    metadata = {
        'age_group': query_params.get('ageGroup', [None])[0],
        'event_course': query_params.get('eventCourse', [None])[0],  # Y (Yards) or L (Long Course)
        'gender': query_params.get('gender', [None])[0],
        'season_id': query_params.get('seasonId', [None])[0],
        'sort_by': query_params.get('sortBy', [None])[0],
        'region': query_params.get('region', [None])[0],
    }
    
    print(f"Extracting teams from URL: {url}")
    print(f"  LSC Code: {lsc_code}")
    print(f"  Filters: {metadata}")
    
    page = 1
    seen_team_ids = set()
    
    # For teams pages, we need to use Selenium as they're often blocked
    # Initialize Selenium immediately for teams pages
    if '/teams/' in url:
        use_selenium = True
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument(f"user-agent={REQUEST_HEADERS['User-Agent']}")
        driver = webdriver.Chrome(options=chrome_options)
    
    try:
        while True:
            # Build URL with page parameter
            current_url = url
            if 'page=' not in url:
                separator = '&' if '?' in url else '?'
                current_url = f"{url}{separator}page={page}"
            else:
                # Replace existing page parameter
                if page > 1:
                    import re
                    current_url = re.sub(r'page=\d+', f'page={page}', url)
                else:
                    current_url = url
            
            try:
                if use_selenium:
                    # Use Selenium for teams pages
                    driver.get(current_url)
                    # Wait for content to load
                    try:
                        WebDriverWait(driver, 10).until(
                            EC.presence_of_element_located((By.TAG_NAME, "table"))
                        )
                    except:
                        pass
                    _time.sleep(3)  # Additional wait for JavaScript
                    html = driver.page_source
                else:
                    # Try with requests first (for swimmers pages)
                    response = requests.get(current_url, headers=REQUEST_HEADERS, timeout=10)
                    response.encoding = 'utf-8'
                    html = response.text
                    
                    # Check if we got blocked
                    if response.status_code == 403 or '403' in html or 'forbidden' in html.lower():
                        print(f"  Requests blocked (403), switching to Selenium...")
                        use_selenium = True
                        # Initialize Selenium driver
                        chrome_options = Options()
                        chrome_options.add_argument("--headless")
                        chrome_options.add_argument("--no-sandbox")
                        chrome_options.add_argument("--disable-dev-shm-usage")
                        chrome_options.add_argument(f"user-agent={REQUEST_HEADERS['User-Agent']}")
                        driver = webdriver.Chrome(options=chrome_options)
                        driver.get(current_url)
                        _time.sleep(3)
                        html = driver.page_source
                
                soup = bs(html, 'html.parser')
                
                # Debug: Check what's on the page (first page only)
                if page == 1:
                    page_title = soup.find('title')
                    if page_title:
                        title_text = page_title.text.strip()
                        print(f"    Page title: {title_text}")
                    
                    # Count team links
                    all_team_links = soup.find_all('a', href=lambda x: x and '/team/' in str(x))
                    print(f"    Found {len(all_team_links)} team links on page")
                
                # Find teams - try table first, then direct links
                teams_table = soup.find('table', attrs={'class': 'c-table-clean'})
                if not teams_table:
                    teams_table = soup.find('table', class_=lambda x: x and 'table' in str(x).lower() if x else False)
                if not teams_table:
                    teams_table = soup.find('table')
                
                found_teams_this_page = 0
                
                if teams_table:
                    tbody = teams_table.find('tbody')
                    if tbody:
                        rows = tbody.find_all('tr')
                    else:
                        rows = teams_table.find_all('tr')
                    
                    # Skip header row
                    if rows and len(rows) > 0:
                        rows = rows[1:] if 'header' in str(rows[0]).lower() or rows[0].find('th') else rows
                    
                    for row in rows:
                        try:
                            cells = row.find_all('td')
                            if len(cells) < 1:
                                continue
                            
                            # Find team link in any cell
                            team_link = None
                            for cell in cells:
                                link = cell.find('a')
                                if link and '/team/' in link.get('href', ''):
                                    team_link = link
                                    break
                            
                            if not team_link:
                                continue
                            
                            team_name = team_link.text.strip()
                            team_href = team_link.get('href', '')
                            
                            # Extract team ID from URL
                            if '/team/' in team_href:
                                parts = team_href.split('/team/')
                                if len(parts) > 1:
                                    team_id_str = parts[1].rstrip('/').split('/')[0]
                                    if team_id_str and team_id_str.isdigit():
                                        team_id = int(team_id_str)
                                        if team_id not in seen_team_ids:
                                            seen_team_ids.add(team_id)
                                            
                                            # Extract additional info from row if available
                                            team_state = None
                                            team_city = None
                                            if len(cells) > 1:
                                                # Try to extract location info
                                                location_cell = cells[1] if len(cells) > 1 else None
                                                if location_cell:
                                                    location_text = location_cell.text.strip()
                                                    # Try to parse state/city if available
                                            
                                            team_data = {
                                                'team_name': team_name,
                                                'team_ID': team_id,
                                                'team_type': 'club',
                                                'organization_type': 'club',
                                                'lsc_code': lsc_code,
                                                'region_code': lsc_code,
                                                'team_state': team_state,
                                                'team_city': team_city,
                                                # Add metadata from query parameters
                                                'age_group': metadata['age_group'],
                                                'event_course': metadata['event_course'],
                                                'gender': metadata['gender'],
                                                'season_id': int(metadata['season_id']) if metadata['season_id'] else None,
                                                'sort_by': metadata['sort_by'],
                                            }
                                            teams.append(team_data)
                                            found_teams_this_page += 1
                        except Exception as e:
                            continue
                
                # If no teams found in table, try finding team links directly in the page
                if found_teams_this_page == 0:
                    team_links = soup.find_all('a', href=lambda x: x and '/team/' in str(x))
                    for link in team_links:
                        try:
                            team_name = link.text.strip()
                            if not team_name or len(team_name) < 2:
                                continue
                            
                            team_href = link.get('href', '')
                            if '/team/' in team_href:
                                parts = team_href.split('/team/')
                                if len(parts) > 1:
                                    team_id_str = parts[1].rstrip('/').split('/')[0]
                                    if team_id_str and team_id_str.isdigit():
                                        team_id = int(team_id_str)
                                        if team_id not in seen_team_ids:
                                            seen_team_ids.add(team_id)
                                            team_data = {
                                                'team_name': team_name,
                                                'team_ID': team_id,
                                                'team_type': 'club',
                                                'organization_type': 'club',
                                                'lsc_code': lsc_code,
                                                'region_code': lsc_code,
                                                'team_state': None,
                                                'age_group': metadata['age_group'],
                                                'event_course': metadata['event_course'],
                                                'gender': metadata['gender'],
                                                'season_id': int(metadata['season_id']) if metadata['season_id'] else None,
                                                'sort_by': metadata['sort_by'],
                                            }
                                            teams.append(team_data)
                                            found_teams_this_page += 1
                        except Exception:
                            continue
                
                # Reset consecutive empty counter if we found teams
                if found_teams_this_page > 0:
                    if hasattr(get_club_teams_from_url, '_consecutive_empty'):
                        get_club_teams_from_url._consecutive_empty = 0
                
                # Check if we found any teams on this page
                if found_teams_this_page == 0:
                    if page == 1:
                        print(f"    Warning: No teams found on first page")
                        break
                    else:
                        # Track consecutive empty pages
                        if not hasattr(get_club_teams_from_url, '_consecutive_empty'):
                            get_club_teams_from_url._consecutive_empty = 0
                        get_club_teams_from_url._consecutive_empty += 1
                        
                        if get_club_teams_from_url._consecutive_empty >= 5:
                            print(f"    No new teams for 5 consecutive pages, stopping pagination")
                            break
                
                if page == 1:
                    print(f"    Found {found_teams_this_page} teams on page {page}, continuing...")
                
                # Check if there's a next page
                pagination = soup.find('div', class_='c-pagination') or soup.find('ul', class_='pagination')
                has_next = False
                
                if pagination:
                    next_link = pagination.find('a', string=lambda x: x and 'Next' in str(x) if x else False)
                    if next_link:
                        classes = next_link.get('class', [])
                        if 'disabled' not in str(classes):
                            has_next = True
                    
                    if not has_next:
                        page_links = pagination.find_all('a', href=True)
                        for link in page_links:
                            href = link.get('href', '')
                            if f'page={page + 1}' in href or (link.text.strip().isdigit() and int(link.text.strip()) > page):
                                has_next = True
                                break
                
                if not has_next:
                    if page >= 50:
                        print(f"    Reached page limit (50), stopping")
                        break
                
                page += 1
                _time.sleep(1)  # Be polite to the server
                
            except requests.exceptions.RequestException as e:
                if not use_selenium:
                    print(f"  Requests failed, trying Selenium: {e}")
                    use_selenium = True
                    continue
                else:
                    print(f"Error fetching page {page}: {e}")
                    break
            except Exception as e:
                print(f"Error fetching page {page}: {e}")
                break
        
    finally:
        if driver:
            try:
                driver.close()
            except:
                pass
    
    # Save to database if requested
    if save_to_db and teams:
        try:
            from .. import database as db
            db.save_teams(teams)
            print(f"\n✓ Saved {len(teams)} teams to database")
        except Exception as e:
            print(f"\n✗ Error saving to database: {e}")
    
    return teams


def get_club_teams_by_lsc(lsc_code, season_id=-1, year=-1):
    """
    Get all club teams for a specific LSC (Local Swimming Committee)
    
    Args:
        lsc_code: LSC code (e.g., 'PN' for Pacific Northwest)
        season_id: Season ID (optional)
        year: Year (optional, used if season_id not provided)
    
    Returns:
        List of team dictionaries with:
        - team_name: Name of the club team
        - team_ID: SwimCloud team ID
        - team_type: 'club' (to distinguish from college teams)
        - lsc_code: LSC code
        - team_state: State abbreviation (if available)
    """
    if year != -1:
        season_id = getSeasonID(year)
    elif season_id == -1:
        # Default to current season
        from ..config import DEFAULT_SEASON_ID
        season_id = DEFAULT_SEASON_ID
    
    teams = []
    page = 1
    driver = None
    use_selenium = False
    
    try:
        while True:
            # Use swimmers page instead - it contains team links
            # URL pattern: /country/usa/club/lsc/{lsc_code}/swimmers/
            url = f'https://www.swimcloud.com/country/usa/club/lsc/{lsc_code}/swimmers/?page={page}'
            
            try:
                if not use_selenium:
                    # Try with requests first (faster, less likely to be blocked)
                    response = requests.get(url, headers=REQUEST_HEADERS, timeout=10)
                    response.encoding = 'utf-8'
                    html = response.text
                    
                    # Check if we got blocked
                    if response.status_code == 403 or '403' in html or 'forbidden' in html.lower():
                        print(f"  Requests blocked (403), switching to Selenium...")
                        use_selenium = True
                        # Initialize Selenium driver
                        chrome_options = Options()
                        chrome_options.add_argument("--headless")
                        chrome_options.add_argument("--no-sandbox")
                        chrome_options.add_argument("--disable-dev-shm-usage")
                        chrome_options.add_argument(f"user-agent={REQUEST_HEADERS['User-Agent']}")
                        driver = webdriver.Chrome(options=chrome_options)
                        driver.get(url)
                        _time.sleep(3)
                        html = driver.page_source
                else:
                    # Use Selenium (already initialized)
                    driver.get(url)
                    # Wait for content to load - teams might be loaded via JavaScript
                    try:
                        WebDriverWait(driver, 10).until(
                            EC.presence_of_element_located((By.TAG_NAME, "table"))
                        )
                    except:
                        pass  # Continue even if table not found
                    _time.sleep(3)  # Additional wait for JavaScript
                    html = driver.page_source
                
                soup = bs(html, 'html.parser')
                
                # Debug: Check what's on the page (first page only)
                if page == 1:
                    page_title = soup.find('title')
                    if page_title:
                        title_text = page_title.text.strip()
                        print(f"    Page title: {title_text}")
                        if '403' in title_text or 'forbidden' in title_text.lower():
                            print(f"    Warning: Still getting 403, page may be blocking scrapers")
                    
                    # Count team links
                    all_team_links = soup.find_all('a', href=lambda x: x and '/team/' in str(x))
                    print(f"    Found {len(all_team_links)} team links on page")
                
                # Find teams - try table first, then direct links
                teams_table = soup.find('table', attrs={'class': 'c-table-clean'})
                if not teams_table:
                    teams_table = soup.find('table', class_=lambda x: x and 'table' in str(x).lower() if x else False)
                if not teams_table:
                    teams_table = soup.find('table')
                
                found_teams_this_page = 0
                seen_team_ids = set([t['team_ID'] for t in teams])
                
                if teams_table:
                    tbody = teams_table.find('tbody')
                    if tbody:
                        rows = tbody.find_all('tr')
                    else:
                        rows = teams_table.find_all('tr')
                    
                    # Skip header row
                    if rows and len(rows) > 0:
                        rows = rows[1:] if 'header' in str(rows[0]).lower() or rows[0].find('th') else rows
                    
                    for row in rows:
                        try:
                            cells = row.find_all('td')
                            if len(cells) < 1:
                                continue
                            
                            # Find team link in any cell
                            team_link = None
                            for cell in cells:
                                link = cell.find('a')
                                if link and '/team/' in link.get('href', ''):
                                    team_link = link
                                    break
                            
                            if not team_link:
                                continue
                            
                            team_name = team_link.text.strip()
                            team_href = team_link.get('href', '')
                            
                            # Extract team ID from URL
                            if '/team/' in team_href:
                                parts = team_href.split('/team/')
                                if len(parts) > 1:
                                    team_id_str = parts[1].rstrip('/').split('/')[0]
                                    if team_id_str and team_id_str.isdigit():
                                        team_id = int(team_id_str)
                                        if team_id not in seen_team_ids:
                                            seen_team_ids.add(team_id)
                                            teams.append({
                                                'team_name': team_name,
                                                'team_ID': team_id,
                                                'team_type': 'club',
                                                'organization_type': 'club',
                                                'lsc_code': lsc_code,
                                                'region_code': lsc_code,
                                                'team_state': None,
                                            })
                                            found_teams_this_page += 1
                        except Exception as e:
                            continue
                
                # If no teams found in table, try finding team links directly in the page
                if found_teams_this_page == 0:
                    team_links = soup.find_all('a', href=lambda x: x and '/team/' in str(x))
                    for link in team_links:
                        try:
                            team_name = link.text.strip()
                            if not team_name or len(team_name) < 2:
                                continue
                            
                            team_href = link.get('href', '')
                            if '/team/' in team_href:
                                parts = team_href.split('/team/')
                                if len(parts) > 1:
                                    team_id_str = parts[1].rstrip('/').split('/')[0]
                                    if team_id_str and team_id_str.isdigit():
                                        team_id = int(team_id_str)
                                        if team_id not in seen_team_ids:
                                            seen_team_ids.add(team_id)
                                            teams.append({
                                                'team_name': team_name,
                                                'team_ID': team_id,
                                                'team_type': 'club',
                                                'organization_type': 'club',
                                                'lsc_code': lsc_code,
                                                'region_code': lsc_code,
                                                'team_state': None,
                                            })
                                            found_teams_this_page += 1
                        except Exception:
                            continue
                
                # Reset consecutive empty counter if we found teams
                if found_teams_this_page > 0:
                    if hasattr(get_club_teams_by_lsc, '_consecutive_empty'):
                        get_club_teams_by_lsc._consecutive_empty = 0
                
                # Check if we found any teams on this page
                if found_teams_this_page == 0:
                    if page == 1:
                        print(f"    Warning: No teams found on first page")
                        break
                    else:
                        # Track consecutive empty pages
                        if not hasattr(get_club_teams_by_lsc, '_consecutive_empty'):
                            get_club_teams_by_lsc._consecutive_empty = 0
                        get_club_teams_by_lsc._consecutive_empty += 1
                        
                        if get_club_teams_by_lsc._consecutive_empty >= 5:
                            print(f"    No new teams for 5 consecutive pages, stopping pagination")
                            break
                
                if page == 1:
                    print(f"    Found {found_teams_this_page} teams on page {page}, continuing...")
                
                # Check if there's a next page
                pagination = soup.find('div', class_='c-pagination') or soup.find('ul', class_='pagination')
                has_next = False
                
                if pagination:
                    next_link = pagination.find('a', string=lambda x: x and 'Next' in str(x) if x else False)
                    if next_link:
                        classes = next_link.get('class', [])
                        if 'disabled' not in str(classes):
                            has_next = True
                    
                    if not has_next:
                        page_links = pagination.find_all('a', href=True)
                        for link in page_links:
                            href = link.get('href', '')
                            if f'page={page + 1}' in href or (link.text.strip().isdigit() and int(link.text.strip()) > page):
                                has_next = True
                                break
                
                if not has_next:
                    if page >= 50:
                        print(f"    Reached page limit (50), stopping")
                        break
                
                page += 1
                _time.sleep(1)  # Be polite to the server
                
            except requests.exceptions.RequestException as e:
                if not use_selenium:
                    print(f"  Requests failed, trying Selenium: {e}")
                    use_selenium = True
                    continue
                else:
                    print(f"Error fetching page {page} for LSC {lsc_code}: {e}")
                    break
            except Exception as e:
                print(f"Error fetching page {page} for LSC {lsc_code}: {e}")
                break
        
    finally:
        if driver:
            try:
                driver.close()
            except:
                pass
    
    return teams


def get_club_teams_by_region(region_name, season_id=-1, year=-1):
    """
    Get all club teams for a region by looking up LSC codes
    
    Args:
        region_name: Region name (e.g., 'Pacific Northwest')
        season_id: Season ID (optional)
        year: Year (optional)
    
    Returns:
        List of team dictionaries
    """
    if region_name not in REGION_TO_LSC:
        print(f"Warning: Unknown region '{region_name}' for club teams")
        return []
    
    lsc_codes = REGION_TO_LSC[region_name]
    all_teams = []
    
    for lsc_code in lsc_codes:
        print(f"Fetching club teams for LSC: {lsc_code}...")
        teams = get_club_teams_by_lsc(lsc_code, season_id=season_id, year=year)
        all_teams.extend(teams)
        print(f"  Found {len(teams)} teams in {lsc_code}")
        _time.sleep(1)  # Be polite to the server
    
    return all_teams


def get_all_club_teams(season_id=-1, year=-1):
    """
    Get all club teams from all LSCs (this will take a while!)
    
    Args:
        season_id: Season ID (optional)
        year: Year (optional)
    
    Returns:
        List of team dictionaries
    """
    all_teams = []
    
    for lsc_code in LSC_CODES.keys():
        print(f"Fetching club teams for LSC: {lsc_code} ({LSC_CODES[lsc_code]})...")
        teams = get_club_teams_by_lsc(lsc_code, season_id=season_id, year=year)
        all_teams.extend(teams)
        print(f"  Found {len(teams)} teams")
        _time.sleep(1)  # Be polite to the server
    
    return all_teams
