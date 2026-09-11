# Database Setup Guide for SwimScraper

This guide will help you set up PostgreSQL and configure SwimScraper to store scraped data in a database.

## Prerequisites

- PostgreSQL 14+ installed (already installed on your system)
- Python 3.6+
- All Python dependencies installed

## Step 1: Start PostgreSQL

PostgreSQL needs to be running before you can use the database features.

### Option A: Using Homebrew Services (Recommended)
```bash
brew services start postgresql@14
```

### Option B: Manual Start
```bash
pg_ctl -D /opt/homebrew/var/postgresql@14 start
```

### Verify PostgreSQL is Running
```bash
psql -U $(whoami) -d postgres -c "SELECT version();"
```

If you see a version number, PostgreSQL is running correctly.

## Step 2: Set Up Python Virtual Environment

It's recommended to use a virtual environment to avoid conflicts with system Python packages.

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -e .
```

**Note:** Always activate the virtual environment before running scripts:
```bash
source venv/bin/activate
```

Or use the automated setup script:
```bash
./setup.sh
```

## Step 3: Configure Database Connection

The database configuration is in `src/SwimScraper/database.py`. By default, it uses:

- **Host**: localhost
- **Port**: 5432
- **Database**: swimscraper
- **User**: Your system username
- **Password**: (empty by default)

You can override these settings using environment variables:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=swimscraper
export DB_USER=your_username
export DB_PASSWORD=your_password
```

## Step 4: Initialize the Database

**Make sure your virtual environment is activated first!**

Run the initialization script to create the database and schema:

```bash
source venv/bin/activate
python3 src/SwimScraper/init_db.py
```

This will:
1. Create the `swimscraper` database (if it doesn't exist)
2. Create all necessary tables
3. Set up indexes for better query performance

## Step 5: Run the Scraper

**Make sure your virtual environment is activated first!**

Now you can run the scraper with database storage enabled:

```bash
source venv/bin/activate
python -m SwimScraper.scripts.run_scraper
```

See [SCRIPTS.md](SCRIPTS.md) for all available scripts.

Or use the database-enabled functions directly:

```python
from SwimScraper import SwimScraperDB as ss

# Get teams and save to database
teams = ss.getCollegeTeams(conference_names=['ACC'], save_to_db=True)

# Get roster and save to database
roster = ss.getRoster(
    team='University of Pittsburgh',
    team_ID=405,
    gender='M',
    year=2020,
    save_to_db=True
)
```

## Database Schema

The database includes the following tables:

- **teams**: College swimming teams
- **swimmers**: Individual swimmers
- **rosters**: Team rosters (many-to-many relationship)
- **swimmer_events**: Events each swimmer participates in
- **swimmer_times**: Individual swim times
- **meets**: Swimming meets
- **team_meets**: Team-meet relationships
- **meet_events**: Events in each meet
- **college_meet_results**: College meet results
- **pro_meet_results**: Professional meet results
- **team_rankings**: Team rankings by season
- **hs_recruit_rankings**: High school recruit rankings

## Querying the Database

Connect to the database:

```bash
psql -d swimscraper
```

Example queries:

```sql
-- Count teams
SELECT COUNT(*) FROM teams;

-- Count swimmers
SELECT COUNT(*) FROM swimmers;

-- View top teams by ranking
SELECT team_name, swimcloud_points 
FROM team_rankings 
WHERE gender = 'M' AND year = 2020 
ORDER BY swimcloud_points::numeric DESC 
LIMIT 10;

-- View swimmers on a specific team
SELECT s.swimmer_name, r.grade, r.year
FROM swimmers s
JOIN rosters r ON s.swimmer_id = r.swimmer_id
WHERE r.team_id = 405 AND r.gender = 'M'
ORDER BY r.year DESC;
```

## Troubleshooting

### PostgreSQL not starting
- Check if the data directory exists: `ls -la /opt/homebrew/var/postgresql@14`
- Check logs: `tail -f /opt/homebrew/var/log/postgresql@14.log`
- Try initializing the database: `initdb -D /opt/homebrew/var/postgresql@14`

### Connection errors
- Verify PostgreSQL is running: `pg_ctl -D /opt/homebrew/var/postgresql@14 status`
- Check if the database exists: `psql -l | grep swimscraper`
- Verify your user has permissions to create databases

### Import errors
- Make sure psycopg2-binary is installed: `pip install psycopg2-binary`
- Check Python path: `python -c "import psycopg2; print(psycopg2.__version__)"`

## Disabling Database Storage

If you want to use the original functions without database storage, use the original module:

```python
from SwimScraper import SwimScraper as ss

# These functions don't save to database
teams = ss.getCollegeTeams(conference_names=['ACC'])
```

Or set `save_to_db=False` when using the database-enabled functions:

```python
from SwimScraper import SwimScraperDB as ss

teams = ss.getCollegeTeams(conference_names=['ACC'], save_to_db=False)
```
