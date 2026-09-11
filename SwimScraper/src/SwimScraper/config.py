"""
Configuration and constants for SwimScraper
"""
import pandas as pd

# Load teams data
TEAMS_CSV_URL = 'https://raw.githubusercontent.com/maflancer/SwimScraper/main/src/SwimScraper/collegeSwimmingTeams.csv'
teams = pd.read_csv(TEAMS_CSV_URL)

# Event mappings - Y = Yards, S = Short Course Meters, L = Long Course Meters
EVENTS = {
    # Short Course Yards (SCY)
    '25 Y Free': '125Y', '25 Y Back': '225 Y', '25 Y Breast': '325Y', '25 Y Fly': '425Y',
    '50 Y Free': '150Y', '75 Y Free': '175Y', '100 Y Free': '1100Y', '125 Y Free': '1125Y',
    '200 Y Free': '1200Y', '400 Y Free': '1400Y', '500 Y Free': '1500Y', '800 Y Free': '1800Y',
    '1000 Y Free': '11000Y', '1500 Y Free': '11500Y', '1650 Y Free': '11650Y',
    '50 Y Back': '250Y', '100 Y Back': '2100Y', '200 Y Back': '2200Y',
    '50 Y Breast': '350Y', '100 Y Breast': '3100Y', '200 Y Breast': '3200Y',
    '50 Y Fly': '450Y', '100 Y Fly': '4100Y', '200 Y Fly': '4200Y',
    '100 Y IM': '5100Y', '200 Y IM': '5200Y', '400 Y IM': '5400Y',
    '200 Free Relay': 6200, '400 Free Relay': 6400, '800 Free Relay': 6800,
    '200 Medley Relay': 7200, '400 Medley Relay': 7400,
    
    # Diving events
    '1 M Diving': 'H1', '1 M Diving (6 dives)': 'H16', '3 M Diving': 'H3',
    '3 M Diving (6 dives)': 'H36', '7M Diving': 'H75', '7M Diving (5 dives)': 'H75Y',
    'Platform Diving': 'H2', '50 Individual': 'H50', '100 Individual': 'H100', '200 Individual': 'H200',
    
    # Short Course Meters (SCM)
    '25 S Free': '125S', '25 S Back': '225 S', '25 S Breast': '325S', '25 S Fly': '425S',
    '50 S Free': '150S', '75 S Free': '175S', '100 S Free': '1100S', '125 S Free': '1125S',
    '200 S Free': '1200S', '400 S Free': '1400S', '500 S Free': '1500S', '800 S Free': '1800S',
    '1000 S Free': '11000S', '1500 S Free': '11500S', '1650 S Free': '11650S',
    '50 S Back': '250S', '100 S Back': '2100S', '200 S Back': '2200S',
    '50 S Breast': '350S', '100 S Breast': '3100S', '200 S Breast': '3200S',
    '50 S Fly': '450S', '100 S Fly': '4100S', '200 S Fly': '4200S',
    '100 S IM': '5100S', '200 S IM': '5200S', '400 S IM': '5400S',
    
    # Long Course Meters (LCM) - LCS
    '50 L Free': '150L', '100 L Free': '1100L', '200 L Free': '1200L', '400 L Free': '1400L',
    '500 L Free': '1500L', '800 L Free': '1800L', '1000 L Free': '11000L',
    '1500 L Free': '11500L', '1650 L Free': '11650L',
    '50 L Back': '250L', '100 L Back': '2100L', '200 L Back': '2200L',
    '50 L Breast': '350L', '100 L Breast': '3100L', '200 L Breast': '3200L',
    '50 L Fly': '450L', '100 L Fly': '4100L', '200 L Fly': '4200L',
    '100 L IM': '5100L', '200 L IM': '5200L', '400 L IM': '5400L'
}

# US States mapping
US_STATES = {
    'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
    'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
    'District of Columbia': 'DC', 'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI',
    'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS',
    'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
    'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS',
    'Missouri': 'MO', 'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
    'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
    'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK',
    'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
    'South Dakota': 'SD', 'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT',
    'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
    'Wisconsin': 'WI', 'Wyoming': 'WY'
}

# Course type constants
COURSE_TYPES = {
    'SCY': 'Y',  # Short Course Yards
    'SCM': 'S',  # Short Course Meters
    'LCM': 'L'   # Long Course Meters (LCS)
}

# Default values
DEFAULT_SEASON_ID = 24  # Most recent season
DEFAULT_YEAR = 2020

# Request headers
REQUEST_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36',
    'Referer': 'https://google.com/'
}

# For backward compatibility
events = EVENTS
us_states = US_STATES
