"""
Scrapers package - organized scraping functions
"""
from . import teams
from . import clubs
from . import organizations

# Note: swimmers and meets modules will be added later
# For now, import from main SwimScraper module if needed
try:
    from .swimmers import (
        getHSRecruitRankings,
        getPowerIndex,
        getSwimmerEvents,
        getSwimmerTimes
    )
except ImportError:
    # Fallback to main module
    pass

try:
    from .meets import (
        getMeetEventList,
        getCollegeMeetResults,
        getProMeetResults,
        getMeetSimulator
    )
except ImportError:
    # Fallback to main module
    pass

__all__ = [
    # Teams
    'teams',
    'clubs',
]
