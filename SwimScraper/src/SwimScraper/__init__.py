"""
SwimScraper - A package to scrape professional and college swimming data from swimcloud.com
"""

from .SwimScraper import (
    # Helper functions
    cleanName,
    getTeamID,
    getTeamName,
    getSeasonID,
    getYear,
    getEventName,
    getEventID,
    getState,
    getCity,
    convertTime,
    getIndexes,
    
    # Team data functions
    getCollegeTeams,
    getTeamRankingsList,
    
    # Roster data functions
    getRoster,
    getHSRecruitRankings,
    
    # Swimmer data functions
    getPowerIndex,
    getSwimmerEvents,
    getSwimmerTimes,
    
    # Meet data functions
    getTeamMeetList,
    getMeetEventList,
    getCollegeMeetResults,
    getProMeetResults,
    getMeetSimulator,
    
    # Constants
    events,
    us_states,
    teams,
)

__all__ = [
    # Helper functions
    'cleanName',
    'getTeamID',
    'getTeamName',
    'getSeasonID',
    'getYear',
    'getEventName',
    'getEventID',
    'getState',
    'getCity',
    'convertTime',
    'getIndexes',
    
    # Team data functions
    'getCollegeTeams',
    'getTeamRankingsList',
    
    # Roster data functions
    'getRoster',
    'getHSRecruitRankings',
    
    # Swimmer data functions
    'getPowerIndex',
    'getSwimmerEvents',
    'getSwimmerTimes',
    
    # Meet data functions
    'getTeamMeetList',
    'getMeetEventList',
    'getCollegeMeetResults',
    'getProMeetResults',
    'getMeetSimulator',
    
    # Constants
    'events',
    'us_states',
    'teams',
]

__version__ = '0.0.4'
