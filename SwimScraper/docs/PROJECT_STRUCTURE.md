# Project Structure

## Current Organization

```
SwimScraper/
├── src/                          # All source code
│   └── SwimScraper/             # Main package
│       ├── __init__.py          # Package exports
│       ├── config.py            # ✅ Constants (events, states, teams)
│       ├── utils.py             # ✅ Helper functions
│       ├── database.py          # Database operations
│       ├── SwimScraperDB.py     # DB-enabled wrapper
│       ├── lcs_scraper.py       # LCS/LCM functions
│       ├── team_filters.py      # Team filtering utilities
│       ├── init_db.py           # Database initialization
│       ├── migrate_course_type.py  # DB migration
│       ├── getTeamList.py       # Team list scraper utility
│       ├── SwimScraper.py       # ⚠️ Legacy (900 lines - to be refactored)
│       ├── collegeSwimmingTeams.csv  # Team data
│       ├── scrapers/            # ✅ Organized scraping modules
│       │   ├── __init__.py
│       │   └── teams.py        # Team scraping functions
│       └── scripts/            # ✅ Utility scripts
│           ├── __init__.py
│           ├── run_scraper.py
│           ├── fetch_pnw_teams.py
│           ├── fetch_region_teams.py
│           └── fetch_lcs_pnw.py
├── tests/                        # Test files
│   └── tests.py
├── dist/                         # Built packages
├── venv/                         # Virtual environment
├── setup.cfg                     # Package configuration
├── pyproject.toml                # Build configuration
├── README.md                     # Main documentation
├── DATABASE_SETUP.md             # Database setup guide
├── QUICKSTART.md                 # Quick start guide
├── HOW_TEAMS_WORK.md             # Teams documentation
├── LCS_GUIDE.md                  # LCS documentation
├── SCRIPTS.md                    # Scripts guide
├── CODE_ORGANIZATION.md          # Code organization guide
└── setup.sh                      # Setup script
```

## Key Improvements

### ✅ Completed
1. **Config Module** (`config.py`) - All constants separated
2. **Utils Module** (`utils.py`) - Helper functions organized
3. **Scrapers Package** (`scrapers/`) - Domain-organized scraping
4. **Scripts Package** (`scripts/`) - All scripts in src/
5. **No Python files in root** - Everything organized in src/

### 🚧 In Progress
- Complete refactoring of `SwimScraper.py` into scrapers modules
- Database package organization (optional)

### 📋 File Locations

**Configuration & Constants:**
- `src/SwimScraper/config.py` - Events, states, teams, config

**Helper Functions:**
- `src/SwimScraper/utils.py` - All utility functions

**Scraping Functions:**
- `src/SwimScraper/scrapers/teams.py` - Team functions
- `src/SwimScraper/scrapers/swimmers.py` - (To be created)
- `src/SwimScraper/scrapers/meets.py` - (To be created)

**Database:**
- `src/SwimScraper/database.py` - All DB operations
- `src/SwimScraper/init_db.py` - DB initialization

**Scripts:**
- `src/SwimScraper/scripts/` - All utility scripts

**Legacy:**
- `src/SwimScraper/SwimScraper.py` - Original file (still works, being refactored)

## Running Scripts

All scripts are now in `src/SwimScraper/scripts/`:

```bash
# From project root
python -m SwimScraper.scripts.run_scraper
python -m SwimScraper.scripts.fetch_pnw_teams
python -m SwimScraper.scripts.fetch_region_teams
python -m SwimScraper.scripts.fetch_lcs_pnw
```

See [SCRIPTS.md](SCRIPTS.md) for details.
