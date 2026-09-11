"""
Helper functions to filter teams by region, state, or other criteria
"""
from . import SwimScraper as ss

# Regional definitions
REGIONS = {
    'Pacific Northwest': ['WA', 'OR', 'ID'],
    'West Coast': ['WA', 'OR', 'CA', 'ID', 'NV'],
    'Northeast': ['ME', 'NH', 'VT', 'MA', 'RI', 'CT', 'NY', 'NJ', 'PA'],
    'Mid-Atlantic': ['NY', 'NJ', 'PA', 'DE', 'MD', 'DC', 'VA', 'WV'],
    'Southeast': ['KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'AR', 'LA'],
    'Southwest': ['TX', 'OK', 'NM', 'AZ'],
    'Midwest': ['OH', 'MI', 'IN', 'IL', 'WI', 'MN', 'IA', 'MO', 'ND', 'SD', 'NE', 'KS'],
    'Mountain West': ['MT', 'WY', 'CO', 'UT', 'ID', 'NV'],
    'West': ['CA', 'OR', 'WA', 'NV', 'ID', 'MT', 'WY', 'CO', 'UT', 'AZ', 'NM', 'AK', 'HI']
}

def get_teams_by_region(region_name):
    """Get teams by region name"""
    if region_name not in REGIONS:
        raise ValueError(f"Unknown region: {region_name}. Available regions: {list(REGIONS.keys())}")
    
    states = REGIONS[region_name]
    all_teams = ss.getCollegeTeams()
    return [t for t in all_teams if t.get('team_state') in states]

def get_teams_by_states(states):
    """Get teams by list of state abbreviations"""
    all_teams = ss.getCollegeTeams()
    return [t for t in all_teams if t.get('team_state') in states]

def get_teams_by_state(state):
    """Get teams by single state abbreviation"""
    all_teams = ss.getCollegeTeams()
    return [t for t in all_teams if t.get('team_state') == state]

def list_regions():
    """List all available regions"""
    return list(REGIONS.keys())

def get_region_states(region_name):
    """Get list of states in a region"""
    if region_name not in REGIONS:
        raise ValueError(f"Unknown region: {region_name}. Available regions: {list(REGIONS.keys())}")
    return REGIONS[region_name]
