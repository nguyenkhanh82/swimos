# SwimCloud Organization Hierarchy

## Overview

SwimCloud organizes swimming data in a hierarchical structure:

```
Country
└── USA Swimming
    ├── Organization Type
    │   ├── Region
    │   │   └── Team
    │   │       └── Swimmer
```

## Organization Types

### 1. Club (`club`)
- **URL Path**: `/country/usa/club/`
- **Region Type**: LSC (Local Swimming Committee)
- **Example**: Pacific Northwest Swimming (PN), Southern California (CA)
- **URL Pattern**: `https://www.swimcloud.com/country/usa/club/lsc/{lsc_code}/teams/`

### 2. College (`college`)
- **URL Path**: `/country/usa/college/`
- **Region Type**: Conference/Division
- **Example**: ACC, Pac-12, Division 1
- **URL Pattern**: `https://www.swimcloud.com/country/usa/college/teams/`

### 3. High School (`prep`)
- **URL Path**: `/country/usa/prep/`
- **Region Type**: State
- **Example**: Washington, Oregon, California
- **URL Pattern**: `https://www.swimcloud.com/country/usa/prep/state/{state}/teams/`

### 4. Middle School (`mss`)
- **URL Path**: `/country/usa/org/mss/`
- **Region Type**: State/Region
- **Example**: Various middle school teams
- **URL Pattern**: `https://www.swimcloud.com/country/usa/org/mss/teams/`

### 5. College Club Swimming (`ccs`)
- **URL Path**: `/country/usa/org/ccs/`
- **Region Type**: Region
- **Example**: College club swimming teams
- **URL Pattern**: `https://www.swimcloud.com/country/usa/org/ccs/teams/`

### 6. Summer/Rec Swimming (`sls`)
- **URL Path**: `/country/usa/org/sls/`
- **Region Type**: Region
- **Example**: Summer league and recreational swimming
- **URL Pattern**: `https://www.swimcloud.com/country/usa/org/sls/teams/`

## URL Examples

### Swimmer Profile
```
https://www.swimcloud.com/swimmer/{swimmer_id}/
```

### Team Roster
```
https://www.swimcloud.com/team/{team_id}/roster/
```

### Club Teams by LSC
```
https://www.swimcloud.com/country/usa/club/lsc/PN/teams/
```

### High School Teams by State
```
https://www.swimcloud.com/country/usa/prep/state/WA/teams/
```

## Database Schema

The `teams` table now includes:
- `organization_type`: The SwimCloud organization type (club, college, prep, mss, ccs, sls)
- `team_type`: Legacy field (kept for backward compatibility)
- `lsc_code`: LSC code for club teams
- `region_code`: General region identifier (LSC code, state, conference, etc.)

## Usage Examples

### Fetch Club Teams
```bash
python -m SwimScraper.scripts.fetch_teams --org-type club --lsc-code PN --fetch
```

### Fetch College Teams
```bash
python -m SwimScraper.scripts.fetch_teams --org-type college --region "Pacific Northwest" --fetch
```

### Fetch High School Teams
```bash
python -m SwimScraper.scripts.fetch_teams --org-type prep --states WA OR --fetch
```

### Fetch All Types
```bash
python -m SwimScraper.scripts.fetch_teams --org-type all --region "Pacific Northwest" --fetch
```

## Implementation

The hierarchy is implemented in:
- `src/SwimScraper/scrapers/organizations.py`: Organization type definitions and URL patterns
- `src/SwimScraper/scrapers/clubs.py`: Club team scraping (LSC-based)
- `src/SwimScraper/scrapers/teams.py`: College team scraping
- `src/SwimScraper/database.py`: Database schema with organization_type support
