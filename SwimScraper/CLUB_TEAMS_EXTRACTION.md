# Club Teams Extraction from Filtered URLs

This guide explains how to extract club team information from filtered SwimCloud URLs and store them in Supabase.

## Overview

SwimCloud allows filtering teams by various criteria:
- Age group (e.g., UNOV - Unattached/Open)
- Event course (Y - Yards, L - Long Course Meters)
- Gender (M, F)
- Season ID
- Sort order (e.g., top50)

## Usage

### Command Line

```bash
# Extract teams from a filtered URL
python -m SwimScraper.scripts.fetch_club_teams_from_url \
  --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&page=1&region=lsc_PN&seasonId=29&sortBy=top50"

# Test without saving
python -m SwimScraper.scripts.fetch_club_teams_from_url \
  --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F" \
  --no-save
```

### Python API

```python
from SwimScraper.scrapers import clubs

# Extract teams from URL
url = "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29"
teams = clubs.get_club_teams_from_url(url, save_to_db=True)

print(f"Found {len(teams)} teams")
for team in teams:
    print(f"  {team['team_name']} (ID: {team['team_ID']})")
    print(f"    Age Group: {team.get('age_group')}")
    print(f"    Course: {team.get('event_course')}")
    print(f"    Gender: {team.get('gender')}")
```

### Supabase Edge Function

```bash
# Deploy the function
supabase functions deploy fetch-club-teams

# Call it
curl -X POST https://your-project.supabase.co/functions/v1/fetch-club-teams \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29"
  }'
```

### From Your Application

```javascript
const { data, error } = await supabase.functions.invoke('fetch-club-teams', {
  body: { 
    url: 'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
  }
})
```

## URL Parameters

The scraper extracts and stores these parameters from the URL:

- `ageGroup`: Age group filter (e.g., UNOV, 13-14, etc.)
- `eventCourse`: Course type (Y = Yards, L = Long Course Meters)
- `gender`: Gender filter (M, F)
- `seasonId`: Season ID
- `sortBy`: Sort order (e.g., top50)
- `region`: Region filter

## Database Schema

The teams table includes these metadata columns:

- `age_group`: VARCHAR(20)
- `event_course`: VARCHAR(10)
- `filter_gender`: VARCHAR(1)
- `filter_season_id`: INTEGER

## Example: Pacific Northwest Female Teams (Yards, Season 29)

```bash
python -m SwimScraper.scripts.fetch_club_teams_from_url \
  --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&page=1&region=lsc_PN&seasonId=29&sortBy=top50"
```

This will extract all 43 teams matching those filters and save them to the database with the metadata preserved.

## Setting up Cron Job

You can set up a cron job to periodically fetch teams from specific filtered URLs:

```sql
-- In Supabase SQL Editor or via pg_cron
SELECT cron.schedule(
    'fetch-pnw-female-teams',
    '0 2 * * *',  -- Daily at 2 AM
    $$
    SELECT trigger_fetch_club_teams(
        'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
    );
    $$
);
```

## Notes

- The scraper automatically handles pagination
- Teams are deduplicated by team ID
- Metadata from URL filters is preserved in the database
- The scraper uses Selenium for teams pages (they're often blocked for requests)
