# How the Scraper Gets Teams

## Overview

The SwimScraper gets team information from a CSV file that contains all college swimming teams. This CSV is loaded from a GitHub repository when the module is imported.

## Team Data Source

The teams are loaded from:
```
https://raw.githubusercontent.com/maflancer/SwimScraper/main/src/SwimScraper/collegeSwimmingTeams.csv
```

This CSV contains:
- `team_name`: Full name of the team
- `team_ID`: Unique identifier for the team (used in URLs)
- `team_state`: Two-letter state abbreviation (e.g., 'WA', 'OR', 'ID')
- `team_division`: Division (e.g., 'Division 1', 'Division 2')
- `team_conference`: Conference name (e.g., 'ACC', 'Pac-12')

## How to Fetch Teams

### Method 1: By Region (Recommended)

Use the `team_filters` module to get teams by region:

```python
from src.SwimScraper import team_filters as tf

# Get Pacific Northwest teams
pnw_teams = tf.get_teams_by_region('Pacific Northwest')

# Available regions:
# - Pacific Northwest (WA, OR, ID)
# - West Coast (WA, OR, CA, ID, NV)
# - Northeast, Mid-Atlantic, Southeast, etc.
```

### Method 2: By State(s)

```python
from src.SwimScraper import team_filters as tf

# Get teams from specific states
teams = tf.get_teams_by_states(['WA', 'OR', 'ID'])

# Or single state
wa_teams = tf.get_teams_by_state('WA')
```

### Method 3: By Conference

```python
from src.SwimScraper import SwimScraperDB as ss

# Get all ACC teams
acc_teams = ss.getCollegeTeams(conference_names=['ACC'])
```

### Method 4: By Division

```python
from src.SwimScraper import SwimScraperDB as ss

# Get all Division 1 teams
d1_teams = ss.getCollegeTeams(division_names=['Division 1'])
```

### Method 5: By Team Names

```python
from src.SwimScraper import SwimScraperDB as ss

# Get specific teams
teams = ss.getCollegeTeams(team_names=[
    'University of Washington',
    'University of Oregon'
])
```

## Fetching Teams

### Unified Script

Use the unified `fetch_teams.py` script for all team fetching:

```bash
source venv/bin/activate

# Fetch Pacific Northwest teams
python -m SwimScraper.scripts.fetch_teams --region "Pacific Northwest" --fetch --year 2020

# Fetch by states
python -m SwimScraper.scripts.fetch_teams --states WA OR ID --fetch

# Fetch by conference
python -m SwimScraper.scripts.fetch_teams --conference ACC --fetch
```

This will:
1. Find all 26 Pacific Northwest teams (WA, OR, ID)
2. Save them to the database
3. Optionally fetch rosters and meet lists for all teams

### General Regional Script

For any region:

```bash
source venv/bin/activate
python fetch_region_teams.py
```

Then follow the prompts to select a region or enter custom states.

## Example: Fetch All PNW Teams and Their Data

```python
from src.SwimScraper import SwimScraperDB as ss
from src.SwimScraper import team_filters as tf
from src.SwimScraper import database as db

# 1. Get all Pacific Northwest teams
pnw_teams = tf.get_teams_by_region('Pacific Northwest')
print(f"Found {len(pnw_teams)} PNW teams")

# 2. Save teams to database
db.save_teams(pnw_teams)

# 3. Fetch rosters for each team
for team in pnw_teams:
    # Men's roster
    roster_m = ss.getRoster(
        team=team['team_name'],
        team_ID=team['team_ID'],
        gender='M',
        year=2020,
        save_to_db=True
    )
    
    # Women's roster
    roster_f = ss.getRoster(
        team=team['team_name'],
        team_ID=team['team_ID'],
        gender='F',
        year=2020,
        save_to_db=True
    )
    
    print(f"Fetched {team['team_name']}: {len(roster_m)} men, {len(roster_f)} women")
```

## Available Regions

The `team_filters` module includes these predefined regions:

- **Pacific Northwest**: WA, OR, ID
- **West Coast**: WA, OR, CA, ID, NV
- **Northeast**: ME, NH, VT, MA, RI, CT, NY, NJ, PA
- **Mid-Atlantic**: NY, NJ, PA, DE, MD, DC, VA, WV
- **Southeast**: KY, TN, NC, SC, GA, FL, AL, MS, AR, LA
- **Southwest**: TX, OK, NM, AZ
- **Midwest**: OH, MI, IN, IL, WI, MN, IA, MO, ND, SD, NE, KS
- **Mountain West**: MT, WY, CO, UT, ID, NV
- **West**: CA, OR, WA, NV, ID, MT, WY, CO, UT, AZ, NM, AK, HI

## Querying Teams from Database

Once teams are saved, you can query them:

```sql
-- All Pacific Northwest teams
SELECT team_name, team_state, team_conference 
FROM teams 
WHERE team_state IN ('WA', 'OR', 'ID')
ORDER BY team_state, team_name;

-- Count teams by state
SELECT team_state, COUNT(*) 
FROM teams 
WHERE team_state IN ('WA', 'OR', 'ID')
GROUP BY team_state;
```

## Notes

- The team list is loaded once when the module is imported
- Team IDs are used to construct URLs for scraping
- You can filter teams by any combination of: name, state, division, or conference
- The `team_filters` module makes it easy to work with regional groupings
