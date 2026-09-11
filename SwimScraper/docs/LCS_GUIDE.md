# Long Course Season (LCS) Data Guide

## What is LCS?

LCS stands for **Long Course Season**, which uses **Long Course Meters (LCM)** pools (50 meters). This is different from college swimming which typically uses **Short Course Yards (SCY)** pools (25 yards).

- **SCY (Short Course Yards)**: 25-yard pools - typical for college swimming
- **SCM (Short Course Meters)**: 25-meter pools - less common
- **LCM (Long Course Meters)**: 50-meter pools - used in LCS, Olympics, international competitions

## How to Fetch LCS Data

### Using the Unified Script

```bash
source venv/bin/activate

# Fetch LCS data for Pacific Northwest teams
python -m SwimScraper.scripts.fetch_lcs --region "Pacific Northwest" --year 2020

# Fetch LCS data by states
python -m SwimScraper.scripts.fetch_lcs --states WA OR ID --year 2020

# Fetch LCS data by conference
python -m SwimScraper.scripts.fetch_lcs --conference ACC --year 2020
```

This will:
1. Find teams matching your criteria
2. Identify LCS meets (typically summer meets)
3. Fetch LCM swimmer times
4. Get LCM team rankings
5. Save everything to the database with `course_type = 'LCM'`

### For Any Team

```python
from src.SwimScraper import lcs_scraper as lcs

# Fetch LCS data for a specific team
results = lcs.fetchLCSDataForTeam(
    team_name='University of Washington',
    team_ID=288,
    year=2020,
    genders=['M', 'F'],
    save_to_db=True
)
```

### Individual LCS Functions

```python
from src.SwimScraper import lcs_scraper as lcs

# Get LCM team rankings
rankings = lcs.getLCSTeamRankings('M', year=2020)

# Get LCM swimmer times
times = lcs.getLCSSwimmerTimes(swimmer_ID=12345, event_name='100 L Free')

# Get LCS meet results
results = lcs.getLCSMeetResults(meet_ID=123456, event_name='200 L Free', gender='M')

# Find LCS meets for a team
lcs_meets = lcs.findLCSMeets(team_name='University of Washington', year=2020)
```

## Database Schema

The database now tracks course type:

- `swimmer_times.course_type`: 'SCY', 'SCM', or 'LCM'
- `college_meet_results.course_type`: 'SCY', 'SCM', or 'LCM'
- `pro_meet_results.course_type`: 'SCY', 'SCM', or 'LCM' (defaults to 'LCM')

## Querying LCS Data

```sql
-- All LCM swimmer times
SELECT * FROM swimmer_times WHERE course_type = 'LCM';

-- LCS meet results
SELECT * FROM pro_meet_results WHERE course_type = 'LCM';

-- Compare SCY vs LCM times for a swimmer
SELECT event_name, time, course_type, year
FROM swimmer_times
WHERE swimmer_id = 12345
  AND event_name LIKE '%Free%'
ORDER BY event_name, course_type, year;

-- Teams with LCS data
SELECT DISTINCT t.team_name, COUNT(DISTINCT pmr.meet_id) as lcs_meets
FROM teams t
JOIN pro_meet_results pmr ON t.team_id = pmr.team_id
WHERE pmr.course_type = 'LCM'
GROUP BY t.team_name
ORDER BY lcs_meets DESC;
```

## Event Naming

LCS events use the "L" suffix:
- `50 L Free` = 50m Freestyle (LCM)
- `100 L Free` = 100m Freestyle (LCM)
- `200 L Back` = 200m Backstroke (LCM)
- etc.

College events use "Y" suffix:
- `50 Y Free` = 50 yard Freestyle (SCY)
- `100 Y Free` = 100 yard Freestyle (SCY)
- etc.

## Migration

If you have an existing database, run the migration:

```bash
source venv/bin/activate
python src/SwimScraper/migrate_course_type.py
```

This adds `course_type` columns to existing tables.

## Notes

- LCS meets are typically held in summer (June-August)
- Most LCS meets are professional/international competitions
- The `getProMeetResults` function is used for LCS meets
- Team rankings already default to LCM (`eventCourse=L` in URL)
