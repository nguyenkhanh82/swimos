# Scripts Guide

All utility scripts are located in `src/SwimScraper/scripts/` for better organization.

## Available Scripts

### 1. Fetch Teams (Unified)
**Main script for fetching teams and their data**

```bash
# Fetch Pacific Northwest teams
python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --fetch --year 2020

# Fetch teams by states
python -m SwimScraper.scripts.fetch_teams --states WA OR ID --fetch

# Fetch teams by conference
python -m SwimScraper.scripts.fetch_teams --conference ACC --fetch

# Fetch teams by division
python -m SwimScraper.scripts.fetch_teams --division "Division 1" --fetch

# Fetch all teams
python -m SwimScraper.scripts.fetch_teams --all --fetch

# List available regions
python -m SwimScraper.scripts.fetch_teams --list-regions

# Just save teams (don't fetch rosters/meets)
python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest"
```

**Options:**
- `--all`: Fetch all teams
- `--region REGION`: Filter by region name (e.g., "Pacific Northwest")
- `--states STATE [STATE ...]`: Filter by state abbreviations (e.g., WA OR ID)
- `--conference CONF [CONF ...]`: Filter by conference names (e.g., ACC)
- `--division DIV [DIV ...]`: Filter by division names (e.g., "Division 1")
- `--team-names NAME [NAME ...]`: Filter by specific team names
- `--fetch`: Also fetch rosters and meet lists (not just teams)
- `--year YEAR`: Year to fetch data for (default: 2020)
- `--genders {M,F} [{M,F} ...]`: Genders to fetch (default: M F)
- `--list-regions`: List all available regions

### 2. Fetch Swimmer Times
**Fetch all swimmers' times for club teams**

This script fetches complete swimmer data:
1. Gets roster for each team
2. For each swimmer, gets all events they've participated in
3. For each event, gets all their times

```bash
# Fetch times for a single swimmer by ID
python -m SwimScraper.scripts.fetch_swimmer_times --swimmer-id 3397927

# Fetch times for all teams in Pacific Northwest LSC
python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN

# Fetch times for specific teams by ID
python -m SwimScraper.scripts.fetch_swimmer_times --team-ids 7992 8019

# Fetch times for specific teams by name
python -m SwimScraper.scripts.fetch_swimmer_times --team-names "King Aquatic Club" "Bellevue Club Swim Team"

# Fetch only women's times
python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN --genders F

# Fetch times for a specific year
python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN --year 2023

# Test without saving to database
python -m SwimScraper.scripts.fetch_swimmer_times --swimmer-id 3397927 --no-save
```

**Options:**
- `--swimmer-id SWIMMER_ID`: Fetch times for a single swimmer by ID (most efficient for one swimmer)
- `--lsc-code LSC_CODE`: LSC code (e.g., PN for Pacific Northwest)
- `--region REGION`: Region name (e.g., "Pacific Northwest")
- `--team-ids ID [ID ...]`: Specific team IDs to fetch
- `--team-names NAME [NAME ...]`: Specific team names to fetch
- `--genders {M,F} [{M,F} ...]`: Genders to fetch (default: both M and F)
- `--year YEAR`: Year to fetch (default: current season)
- `--no-save`: Don't save to database (for testing)

**Note:** This can take a long time for many teams/swimmers as it fetches detailed data for each swimmer.

### 3. Fetch LCS Data (Long Course Meters)
**Fetch Long Course Season data for teams**

```bash
# Fetch LCS data for Pacific Northwest teams
python -m SwimScraper.scripts.fetch_lcs --region "Pacific Northwest" --year 2020

# Fetch LCS data by states
python -m SwimScraper.scripts.fetch_lcs --states WA OR ID --year 2020

# Fetch LCS data by conference
python -m SwimScraper.scripts.fetch_lcs --conference ACC --year 2020
```

**Options:** Same filtering options as `fetch_teams`, plus:
- `--year YEAR`: Year to fetch LCS data for (default: 2020)
- `--genders {M,F} [{M,F} ...]`: Genders to fetch (default: M F)

### 3. Run Scraper (Example)
**Example script demonstrating basic usage**

```bash
python -m SwimScraper.scripts.run_scraper
```

## Running Scripts

### Option 1: As Module (Recommended)
From project root:
```bash
source venv/bin/activate
python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --fetch
```

### Option 2: Direct Execution
```bash
source venv/bin/activate
cd src/SwimScraper/scripts
python fetch_teams.py --region "Pacific Northwest" --fetch
```

## Script Locations

All scripts are in:
```
src/SwimScraper/scripts/
├── __init__.py
├── run_scraper.py          # Example usage script
├── fetch_teams.py          # Unified team fetcher (replaces fetch_pnw_teams.py, fetch_region_teams.py)
├── fetch_lcs.py            # LCS data fetcher (replaces fetch_lcs_pnw.py)
└── fetch_swimmer_times.py  # Fetch all swimmers' times for teams
```

## Examples

### Fetch Pacific Northwest Teams (2020)
```bash
python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --fetch --year 2020
```

### Fetch All Division 1 Teams
```bash
python -m SwimScraper.scripts.fetch_teams --division "Division 1" --fetch
```

### Fetch Specific Teams
```bash
python -m SwimScraper.scripts.fetch_teams --team-names "University of Washington" "University of Oregon" --fetch
```

### Fetch LCS Data for a Region
```bash
python -m SwimScraper.scripts.fetch_lcs --region "Pacific Northwest" --year 2020
```

### Fetch All Swimmer Times for Club Teams
```bash
# Fetch times for all teams in Pacific Northwest LSC
python -m SwimScraper.scripts.fetch_swimmer_times --lsc-code PN

# Fetch times for specific teams
python -m SwimScraper.scripts.fetch_swimmer_times --team-ids 7992 8019
```

This unified approach ensures all teams are fetched the same way, with filtering options as parameters rather than separate scripts.
