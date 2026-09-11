# Code Organization Guide

## New Structure (Organized)

The codebase has been reorganized for better maintainability:

```
src/SwimScraper/
├── __init__.py              # Main exports (backward compatible)
├── config.py                # ✅ Constants, events, states, teams data
├── utils.py                 # ✅ Helper functions
├── scrapers/                # ✅ Scraping functions by domain
│   ├── __init__.py
│   ├── teams.py            # Team scraping functions
│   ├── swimmers.py         # Swimmer scraping functions
│   └── meets.py            # Meet scraping functions
├── database.py             # Database functions (existing)
├── SwimScraperDB.py        # DB wrapper (existing)
├── lcs_scraper.py          # LCS functions (existing)
├── team_filters.py        # Team filters (existing)
└── SwimScraper.py         # ⚠️ Legacy file (deprecated, kept for compatibility)
```

## Migration Status

### ✅ Completed
- `config.py` - All constants extracted
- `utils.py` - All helper functions extracted
- `scrapers/teams.py` - Team functions organized

### 🚧 In Progress
- `scrapers/swimmers.py` - Swimmer functions
- `scrapers/meets.py` - Meet functions
- Update `__init__.py` for new structure

### 📋 Planned
- Database reorganization (optional)
- Update all scripts to use new imports
- Deprecate old `SwimScraper.py`

## Usage

### New Way (Recommended)
```python
from SwimScraper.scrapers import teams, swimmers, meets
from SwimScraper import config, utils

# Use organized modules
teams_list = teams.getCollegeTeams(conference_names=['ACC'])
roster = teams.getRoster(team='University of Pittsburgh', gender='M', year=2020)
```

### Old Way (Still Works)
```python
from SwimScraper import SwimScraper as ss

# Backward compatible
teams_list = ss.getCollegeTeams(conference_names=['ACC'])
roster = ss.getRoster(team='University of Pittsburgh', gender='M', year=2020)
```

## Benefits

1. **Better Organization**: Functions grouped by domain
2. **Easier Maintenance**: Smaller, focused files
3. **Clearer Dependencies**: Imports show what's needed
4. **Backward Compatible**: Old code still works
5. **Easier Testing**: Can test modules independently

## Next Steps

1. Complete swimmers.py and meets.py modules
2. Update __init__.py to import from new locations
3. Test all functionality
4. Update documentation
5. Eventually deprecate SwimScraper.py
