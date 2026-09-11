# Quick Start Guide - SwimScraper with Database

## Quick Setup (4 Steps)

### 1. Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies
```bash
pip install -e .
```

### 3. Start PostgreSQL
```bash
brew services start postgresql@14
# OR
pg_ctl -D /opt/homebrew/var/postgresql@14 start
```

### 4. Initialize Database
```bash
python3 src/SwimScraper/init_db.py
```

## Run the Scraper

**Important:** Make sure your virtual environment is activated first!

```bash
source venv/bin/activate
python -m SwimScraper.scripts.run_scraper
```

Or from the scripts directory:
```bash
cd src/SwimScraper/scripts
python run_scraper.py
```

## Use in Your Code

```python
from SwimScraper import SwimScraperDB as ss

# All functions now have save_to_db parameter (default: True)
teams = ss.getCollegeTeams(conference_names=['ACC'], save_to_db=True)
roster = ss.getRoster(team='University of Pittsburgh', team_ID=405, gender='M', year=2020)
rankings = ss.getTeamRankingsList('M', year=2020)
```

## Check Your Data

```bash
psql -d swimscraper

# Then run queries like:
SELECT COUNT(*) FROM teams;
SELECT COUNT(*) FROM swimmers;
SELECT * FROM teams LIMIT 10;
```

For more details, see [DATABASE_SETUP.md](DATABASE_SETUP.md)
