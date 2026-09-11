# Supabase Setup Guide

Complete guide to set up Supabase Edge Functions for fetching swimmer times.

## Quick Start

### 1. Deploy Python API (Choose one option)

#### Option A: Railway (Recommended)

1. Go to [Railway.app](https://railway.app)
2. Create new project
3. Add new service → Deploy from GitHub repo
4. Set environment variables:
   - `DATABASE_URL`: Your PostgreSQL connection string
5. Deploy

#### Option B: Render

1. Go to [Render.com](https://render.com)
2. Create new Web Service
3. Connect your GitHub repo
4. Set build command: `pip install -r api/requirements.txt`
5. Set start command: `cd api && uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Set environment variables
7. Deploy

#### Option C: Local Development

```bash
cd api
pip install -r requirements.txt
python main.py
```

### 2. Deploy Supabase Edge Functions

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project (get project ref from Supabase dashboard)
supabase link --project-ref your-project-ref

# Deploy the functions
supabase functions deploy fetch-swimmer-times
supabase functions deploy fetch-club-teams

# Set environment variable for Python API URL
supabase secrets set PYTHON_API_URL=https://your-api.railway.app
```

### 3. Set up Database

Run these SQL commands in Supabase SQL Editor:

```sql
-- Enable pg_net extension (for HTTP calls from database)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Run migrations
\i supabase/migrations/001_create_swimmer_tracking.sql
\i supabase/migrations/002_create_edge_function_trigger.sql

-- Set database settings
ALTER DATABASE postgres SET app.settings.edge_function_url = 'https://your-project.supabase.co/functions/v1';
ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';
```

### 4. Test the Setup

```bash
# Test Edge Function directly
curl -X POST https://your-project.supabase.co/functions/v1/fetch-swimmer-times \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"swimmer_id": 3397927}'

# Test from database
SELECT trigger_fetch_swimmer_times(3397927);
```

## Setting up Cron Job

### Via Supabase Dashboard

1. Go to Database → Cron Jobs
2. Create new cron job:

**Name**: `fetch-swimmer-times-daily`

**Schedule**: `0 2 * * *` (daily at 2 AM)

**SQL**:
```sql
-- Fetch times for swimmers that need updating
SELECT trigger_fetch_swimmer_times(swimmer_id)
FROM swimmers_tracking
WHERE 
    (last_fetched_at < NOW() - INTERVAL '7 days' OR last_fetched_at IS NULL)
    AND status != 'processing'
ORDER BY last_fetched_at NULLS FIRST
LIMIT 10;
```

### Via pg_cron Extension

```sql
-- Enable pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule job
SELECT cron.schedule(
    'fetch-swimmer-times-daily',
    '0 2 * * *',
    $$
    SELECT trigger_fetch_swimmer_times(swimmer_id)
    FROM swimmers_tracking
    WHERE last_fetched_at < NOW() - INTERVAL '7 days'
       OR last_fetched_at IS NULL
    LIMIT 10;
    $$
);
```

## Triggering from Your Application

### Fetch Swimmer Times

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Trigger fetch for a swimmer
const { data, error } = await supabase.functions.invoke('fetch-swimmer-times', {
  body: { swimmer_id: 3397927 }
})

if (error) {
  console.error('Error:', error)
} else {
  console.log('Success:', data)
}
```

### Fetch Club Teams from URL

```typescript
// Fetch teams from a filtered URL
const { data, error } = await supabase.functions.invoke('fetch-club-teams', {
  body: { 
    url: 'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
  }
})

// Or use the unified function
const { data, error } = await supabase.functions.invoke('fetch-swimmer-times', {
  body: { 
    url: 'https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29'
  }
})
```

### Python

```python
from supabase import create_client

supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

response = supabase.functions.invoke(
    'fetch-swimmer-times',
    body={'swimmer_id': 3397927}
)

print(response)
```

## Monitoring

### Check Fetch Status

```sql
SELECT 
    swimmer_id,
    last_fetched_at,
    events_count,
    times_count,
    status,
    error_message,
    updated_at
FROM swimmers_tracking
ORDER BY last_fetched_at DESC
LIMIT 20;
```

### Check Edge Function Logs

```bash
supabase functions logs fetch-swimmer-times
```

## Troubleshooting

### Edge Function Returns 500

1. Check Edge Function logs: `supabase functions logs fetch-swimmer-times`
2. Verify `PYTHON_API_URL` is set correctly
3. Test Python API directly: `curl https://your-api.railway.app/health`

### Python API Not Responding

1. Check API service logs (Railway/Render dashboard)
2. Verify `DATABASE_URL` is set correctly
3. Test locally: `python api/main.py`

### Database Function Not Working

1. Verify pg_net extension is enabled: `SELECT * FROM pg_extension WHERE extname = 'pg_net';`
2. Check database settings are set correctly
3. Test HTTP call manually

## Cost Considerations

- **Supabase Edge Functions**: Free tier includes 500K invocations/month
- **Python API**: Railway free tier or Render free tier available
- **Database**: Included in Supabase plan

For production, consider:
- Rate limiting
- Caching frequently accessed data
- Batch processing multiple swimmers
