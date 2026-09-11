# Code Organization Summary

## ✅ Completed Reorganization

All Python files are now organized within the `src/` directory structure.

### Files Moved

**Scripts moved from root to `src/SwimScraper/scripts/`:**
- ✅ `run_scraper.py` → `src/SwimScraper/scripts/run_scraper.py`
- ✅ `fetch_pnw_teams.py` → `src/SwimScraper/scripts/fetch_pnw_teams.py`
- ✅ `fetch_region_teams.py` → `src/SwimScraper/scripts/fetch_region_teams.py`
- ✅ `fetch_lcs_pnw.py` → `src/SwimScraper/scripts/fetch_lcs_pnw.py`

### New Structure Created

**Configuration & Constants:**
- ✅ `src/SwimScraper/config.py` - Events, states, teams, config values

**Helper Functions:**
- ✅ `src/SwimScraper/utils.py` - All utility functions

**Organized Scrapers:**
- ✅ `src/SwimScraper/scrapers/teams.py` - Team scraping functions
- 🚧 `src/SwimScraper/scrapers/swimmers.py` - (To be created)
- 🚧 `src/SwimScraper/scrapers/meets.py` - (To be created)

**Scripts:**
- ✅ `src/SwimScraper/scripts/` - All utility scripts

## Current File Locations

### All Python Files in `src/`:

```
src/SwimScraper/
├── __init__.py
├── config.py                    ✅ NEW
├── utils.py                     ✅ NEW
├── database.py
├── SwimScraperDB.py
├── lcs_scraper.py
├── team_filters.py
├── init_db.py
├── migrate_course_type.py
├── getTeamList.py
├── SwimScraper.py               ⚠️ Legacy (to be refactored)
├── scrapers/
│   ├── __init__.py
│   └── teams.py                 ✅ NEW
└── scripts/
    ├── __init__.py              ✅ NEW
    ├── run_scraper.py           ✅ MOVED
    ├── fetch_pnw_teams.py       ✅ MOVED
    ├── fetch_region_teams.py    ✅ MOVED
    └── fetch_lcs_pnw.py         ✅ MOVED
```

### Root Directory (No Python Files):

```
SwimScraper/
├── setup.cfg
├── pyproject.toml
├── setup.sh
├── README.md
├── Documentation files (.md)
└── src/                         ← All code here
```

## Running Scripts

All scripts are now in `src/SwimScraper/scripts/`:

```bash
# From project root
source venv/bin/activate
python -m SwimScraper.scripts.run_scraper
python -m SwimScraper.scripts.fetch_pnw_teams
python -m SwimScraper.scripts.fetch_region_teams
python -m SwimScraper.scripts.fetch_lcs_pnw
```

## Benefits

1. ✅ **All Python code in `src/`** - Clean separation
2. ✅ **Organized by function** - Config, utils, scrapers, scripts
3. ✅ **Better maintainability** - Smaller, focused files
4. ✅ **Backward compatible** - Old imports still work
5. ✅ **Clear structure** - Easy to find what you need

## Next Steps (Optional)

- Complete refactoring of `SwimScraper.py` into scrapers modules
- Organize database code into a package (optional)
- Add more documentation
