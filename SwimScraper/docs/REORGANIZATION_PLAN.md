# Code Reorganization Plan

## Current Issues
- `SwimScraper.py` is 900 lines - too large
- Functions mixed together without clear organization
- Helper functions mixed with scraping functions
- Constants mixed with code
- No clear separation of concerns

## New Structure

```
src/SwimScraper/
├── __init__.py              # Main exports (backward compatible)
├── config.py                # Constants (events, states, teams, config)
├── utils.py                 # Helper functions
├── scrapers/                # Scraping functions organized by domain
│   ├── __init__.py
│   ├── teams.py            # Team-related scraping
│   ├── swimmers.py         # Swimmer-related scraping
│   └── meets.py            # Meet-related scraping
├── database/                # Database functionality
│   ├── __init__.py
│   ├── connection.py       # DB connection
│   ├── schema.py           # Schema creation
│   └── models.py           # Save functions
├── lcs/                     # LCS-specific functionality
│   ├── __init__.py
│   └── scraper.py
├── filters/                 # Filtering utilities
│   ├── __init__.py
│   └── team_filters.py
└── legacy/                  # Keep old files for reference
    └── SwimScraper.py       # Original (deprecated)
```

## Migration Strategy

1. Create new organized structure
2. Update __init__.py to import from new locations
3. Keep old SwimScraper.py for backward compatibility (deprecated)
4. Update all scripts to use new imports
5. Test everything works
6. Eventually remove legacy files

## Function Organization

### config.py
- EVENTS dictionary
- US_STATES dictionary
- teams DataFrame
- REQUEST_HEADERS
- DEFAULT values

### utils.py
- clean_name()
- get_team_id()
- get_team_name()
- get_season_id()
- get_year()
- get_event_name()
- get_event_id()
- get_state()
- get_city()
- convert_time()
- get_indexes()

### scrapers/teams.py
- getCollegeTeams()
- getTeamRankingsList()
- getRoster()
- getTeamMeetList()

### scrapers/swimmers.py
- getHSRecruitRankings()
- getPowerIndex()
- getSwimmerEvents()
- getSwimmerTimes()

### scrapers/meets.py
- getMeetEventList()
- getCollegeMeetResults()
- getProMeetResults()
- getMeetSimulator()

### database/
- connection.py: get_connection(), create_database()
- schema.py: create_schema()
- models.py: All save_* functions
