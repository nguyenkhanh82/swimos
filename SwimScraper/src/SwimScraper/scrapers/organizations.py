"""
Organization type definitions and helpers for SwimCloud hierarchy

SwimCloud Structure:
Country -> USA Swimming -> Organization Type -> Region -> Team -> Swimmer

Organization Types:
- club: USA Swimming Club teams (organized by LSC regions)
- college: College/University teams (organized by conferences/divisions)
- prep: High School teams
- mss: Middle School teams
- ccs: College Club Swimming teams
- sls: Summer/Rec Swimming
"""
from typing import List, Dict, Optional

# Organization type constants
ORG_TYPES = {
    'club': {
        'name': 'USA Swimming Club',
        'url_path': 'club',
        'region_type': 'lsc',  # Local Swimming Committee
        'description': 'USA Swimming club teams organized by LSC regions'
    },
    'college': {
        'name': 'College',
        'url_path': 'college',
        'region_type': 'conference',  # Conferences/Divisions
        'description': 'College and university teams'
    },
    'prep': {
        'name': 'High School',
        'url_path': 'prep',
        'region_type': 'state',  # Typically organized by state
        'description': 'High school teams'
    },
    'mss': {
        'name': 'Middle School',
        'url_path': 'org/mss',
        'region_type': 'state',
        'description': 'Middle school teams'
    },
    'ccs': {
        'name': 'College Club Swimming',
        'url_path': 'org/ccs',
        'region_type': 'region',
        'description': 'College club swimming teams'
    },
    'sls': {
        'name': 'Summer/Rec Swimming',
        'url_path': 'org/sls',
        'region_type': 'region',
        'description': 'Summer league and recreational swimming'
    }
}

# URL patterns for different organization types
URL_PATTERNS = {
    'club': {
        'teams_by_region': 'https://www.swimcloud.com/country/usa/club/lsc/{region}/teams/',
        'swimmers_by_region': 'https://www.swimcloud.com/country/usa/club/lsc/{region}/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    },
    'college': {
        'teams': 'https://www.swimcloud.com/country/usa/college/teams/',
        'swimmers': 'https://www.swimcloud.com/country/usa/college/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    },
    'prep': {
        'teams_by_state': 'https://www.swimcloud.com/country/usa/prep/state/{state}/teams/',
        'swimmers_by_state': 'https://www.swimcloud.com/country/usa/prep/state/{state}/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    },
    'mss': {
        'teams': 'https://www.swimcloud.com/country/usa/org/mss/teams/',
        'swimmers': 'https://www.swimcloud.com/country/usa/org/mss/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    },
    'ccs': {
        'teams': 'https://www.swimcloud.com/country/usa/org/ccs/teams/',
        'swimmers': 'https://www.swimcloud.com/country/usa/org/ccs/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    },
    'sls': {
        'teams': 'https://www.swimcloud.com/country/usa/org/sls/teams/',
        'swimmers': 'https://www.swimcloud.com/country/usa/org/sls/swimmers/',
        'team_roster': 'https://www.swimcloud.com/team/{team_id}/roster/',
    }
}


def get_org_type_info(org_type: str) -> Optional[Dict]:
    """Get information about an organization type"""
    return ORG_TYPES.get(org_type)


def list_org_types() -> List[str]:
    """List all available organization types"""
    return list(ORG_TYPES.keys())


def get_url_pattern(org_type: str, pattern_name: str, **kwargs) -> Optional[str]:
    """
    Get a URL pattern for a specific organization type
    
    Args:
        org_type: Organization type (club, college, prep, etc.)
        pattern_name: Name of the pattern (e.g., 'teams_by_region')
        **kwargs: Variables to fill in the pattern (e.g., region='PN', state='WA')
    
    Returns:
        Formatted URL string or None if pattern not found
    """
    if org_type not in URL_PATTERNS:
        return None
    
    patterns = URL_PATTERNS[org_type]
    if pattern_name not in patterns:
        return None
    
    url = patterns[pattern_name]
    return url.format(**kwargs)


def get_swimmer_url(swimmer_id: int) -> str:
    """Get the URL for a swimmer profile"""
    return f'https://www.swimcloud.com/swimmer/{swimmer_id}/'


def get_team_url(team_id: int) -> str:
    """Get the URL for a team page"""
    return f'https://www.swimcloud.com/team/{team_id}/'


def is_valid_org_type(org_type: str) -> bool:
    """Check if an organization type is valid"""
    return org_type in ORG_TYPES
