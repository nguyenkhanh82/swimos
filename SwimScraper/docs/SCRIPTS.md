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

### 2. Fetch LCS Data (Long Course Meters)
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
└── fetch_lcs.py            # LCS data fetcher (replaces fetch_lcs_pnw.py)
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

This unified approach ensures all teams are fetched the same way, with filtering options as parameters rather than separate scripts.
