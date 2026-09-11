# Quick Start: Extract Club Teams from Filtered URLs

## What This Does

Extracts club team information from SwimCloud filtered team pages and stores them in your Supabase database with all filter metadata preserved.

## Example URL

```
https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&page=1&region=lsc_PN&seasonId=29&sortBy=top50
```

This URL filters for:
- **LSC**: Pacific Northwest (PN)
- **Age Group**: UNOV (Unattached/Open)
- **Course**: Y (Yards)
- **Gender**: F (Female)
- **Season**: 29
- **Sort**: top50

## Quick Usage

### 1. Command Line (Local)

```bash
# Extract and save to database
python -m SwimScraper.scripts.fetch_club_teams_from_url \
  --url "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29"
```

### 2. Supabase Edge Function

```bash
# Deploy
supabase functions deploy fetch-club-teams

# Call it
curl -X POST https://your-project.supabase.co/functions/v1/fetch-club-teams \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29"
  }'
```

### 3. From Your App

```javascript
const { data, error } = await supabase.functions.invoke('fetch-club-teams', {
  body: { 
    url: 'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
  }
})
```

## What Gets Stored

Each team is saved with:
- Basic info: `team_name`, `team_id`, `lsc_code`
- Filter metadata: `age_group`, `event_course`, `filter_gender`, `filter_season_id`
- Organization type: `organization_type='club'`

## Query Teams by Filter

```sql
-- Get all female teams from season 29
SELECT team_name, age_group, event_course, filter_gender, filter_season_id
FROM teams
WHERE organization_type = 'club'
  AND filter_gender = 'F'
  AND filter_season_id = 29
ORDER BY team_name;
```

## Setup for Supabase

1. **Run database migration**:
   ```sql
   -- Run supabase/migrations/003_add_team_metadata_columns.sql
   ```

2. **Deploy Edge Function**:
   ```bash
   supabase functions deploy fetch-club-teams
   ```

3. **Set Python API URL**:
   ```bash
   supabase secrets set PYTHON_API_URL=https://your-api.railway.app
   ```

## Result

✅ **43 teams** extracted from the example URL  
✅ All metadata preserved (age group, course, gender, season)  
✅ Stored in Supabase database  
✅ Ready for querying and analysis
