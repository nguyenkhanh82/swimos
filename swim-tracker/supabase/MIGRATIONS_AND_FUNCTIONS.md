# Supabase Migrations and Edge Functions

This directory contains migrations and edge functions for the SwimTracker project.

## New Migrations (from SwimScraper)

### 20260125000006_add_team_metadata_columns.sql
Adds metadata columns to the `teams` table for storing filter parameters:
- `age_group` (VARCHAR(20))
- `event_course` (VARCHAR(10)) - Y (Yards) or L (Long Course)
- `filter_gender` (VARCHAR(1)) - M or F
- `filter_season_id` (INTEGER)
- `organization_type` (VARCHAR(20)) - club, college, etc.
- `lsc_code` (VARCHAR(10)) - Local Swimming Committee code
- `region_code` (VARCHAR(50))

### 20260125000007_create_swimmer_tracking.sql
Creates `swimmers_tracking` table to track when swimmers were last fetched:
- `swimmer_id` (PRIMARY KEY)
- `last_fetched_at` (TIMESTAMP)
- `events_count` (INTEGER)
- `times_count` (INTEGER)
- `status` (VARCHAR) - pending, processing, completed, error
- `error_message` (TEXT)

### 20260125000008_create_edge_function_trigger.sql
Creates database functions to trigger Edge Functions:
- `trigger_fetch_swimmer_times(swimmer_id)` - Triggers fetch-swimmer-times-swimcloud
- `trigger_fetch_club_teams(url)` - Triggers fetch-club-teams (url is optional, defaults to Pacific Northwest)

**Note:** Requires `pg_net` extension to be enabled.

## Edge Functions

### fetch-club-teams
Fetches club teams from SwimCloud. **One-time bulk import** for Pacific Northwest region.

**Purpose:** Used for initial data import to fetch all teams and swimmers from Pacific Northwest.

**Default URL:** Pacific Northwest teams (`https://www.swimcloud.com/country/usa/club/lsc/PN/teams/`)

**Usage:**
```javascript
// Use default Pacific Northwest URL
const { data } = await supabase.functions.invoke('fetch-club-teams', {
  body: {}
})

// Or specify a custom URL
const { data } = await supabase.functions.invoke('fetch-club-teams', {
  body: { 
    url: 'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
  }
})
```

**Implementation:**
- Directly scrapes SwimCloud using Deno's HTML parsing capabilities
- Uses `deno_dom` library for parsing HTML
- Extracts team information (name, ID, location) from SwimCloud pages
- Automatically saves teams to the `teams` table

**Workflow:**
1. Run this function once to fetch all Pacific Northwest clubs
2. Function scrapes the SwimCloud teams page
3. Teams are automatically saved to the database

### fetch-swimmer-times-swimcloud
Fetches and updates swimmer times from SwimCloud. **On-demand updates** when users login or use the app.

**Purpose:** Updates individual swimmer times on-demand, not for bulk import.

**Usage:**
```javascript
const { data } = await supabase.functions.invoke('fetch-swimmer-times-swimcloud', {
  body: { swimmer_id: 3397927 } // SwimCloud swimmer ID
})
```

**Implementation:**
- Directly scrapes SwimCloud swimmer times page using Deno's HTML parsing
- Uses `deno_dom` library for parsing HTML
- Extracts event names, times, dates, meet names, and personal best indicators
- Automatically saves times to the `swim_times` table
- Updates `last_fetched_at` timestamp in `swimmers` table

**Workflow:**
- Called when user logs in or views their swimmer profile
- Scrapes the SwimCloud times page for the given swimmer ID
- Saves new times to the database (skips duplicates)
- Updates `last_fetched_at` timestamp
- Uses `swimcloud_id` to match the swimmer record

**Note:** This function only handles swimmer times fetching. Club teams are handled separately by `fetch-club-teams`.

## Setup

1. **Run migrations:**
   ```bash
   supabase db push
   ```

2. **Deploy functions:**
   ```bash
   supabase functions deploy fetch-club-teams
   supabase functions deploy fetch-swimmer-times-swimcloud
   ```
   
   **Note:** 
   - `fetch-swimmer-times` (USA Swimming) has been removed. We only use SwimCloud as the data source.
   - Both functions now scrape SwimCloud directly - no external Python API needed.
   - Functions use `deno_dom` library for HTML parsing (automatically imported).

4. **Enable pg_net extension:**
   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_net;
   ```

5. **Set database settings:**
   ```sql
   ALTER DATABASE postgres SET app.settings.edge_function_url = 'https://your-project.supabase.co/functions/v1';
   ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';
   ```

## Usage Examples

### One-Time: Fetch All Pacific Northwest Club Teams
```sql
-- Uses default Pacific Northwest URL
SELECT trigger_fetch_club_teams(NULL);

-- Or specify a custom URL
SELECT trigger_fetch_club_teams(
  'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
);
```

**Note:** This is a one-time bulk import. The function directly scrapes SwimCloud and saves teams to the database.

### On-Demand: Fetch/Update Swimmer Times
```sql
-- Update times for a specific swimmer (called when user logs in or views profile)
SELECT trigger_fetch_swimmer_times(3397927); -- SwimCloud swimmer ID
```

### Architecture Overview

**Data Flow:**
1. **One-Time Bulk Import:**
   - `fetch-club-teams` → Directly scrapes SwimCloud teams page
   - Extracts team information (name, ID, location)
   - Stores teams in `teams` table

2. **On-Demand Updates:**
   - User logs in or views swimmer profile
   - `fetch-swimmer-times-swimcloud` → Directly scrapes SwimCloud swimmer times page
   - Extracts event names, times, dates, meet names
   - Stores new times in `swim_times` table (skips duplicates)
   - Updates `last_fetched_at` timestamp in `swimmers` table

**Technical Details:**
- Both functions use Deno's built-in `fetch()` for HTTP requests
- HTML parsing is done with `deno_dom` library (imported automatically)
- No external services required - all scraping happens in Edge Functions
- Functions include error handling and duplicate prevention

**No Cron Jobs Needed:** Club teams are fetched once. Swimmer times are updated on-demand when users interact with the app.
