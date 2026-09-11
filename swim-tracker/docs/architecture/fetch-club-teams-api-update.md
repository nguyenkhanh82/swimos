# Fetch Club Teams - API Integration Update

## Overview

Updated `fetch-club-teams` Edge Function to use SwimCloud API instead of HTML scraping, with dynamic profile-based filtering.

## Key Changes

### 1. Replaced HTML Scraping with API Calls

**Before**: Scraped HTML pages using DOMParser
**After**: Uses `https://www.swimcloud.com/api/performances/top_rankings/` API

**Benefits**:
- More reliable (no HTML parsing)
- Faster (direct JSON response)
- Better data quality (structured response)
- Includes team IDs automatically
- Built-in pagination support

### 2. Dynamic Season Fetching

**New Function**: `fetchSeasons()`
- Calls `https://www.swimcloud.com/api/seasonchoices/`
- Returns available seasons with labels and dates
- Defaults to last 4 seasons if not specified

### 3. Swimmer Profile Integration

**New Function**: `getSwimmerProfile()`
- Fetches swimmer data from database
- Calculates age group from `birth_date`
- Gets `gender` from swimmer record
- Sets default region (currently `lsc_PN`)

**New Function**: `calculateAgeGroup()`
- Converts birth date to SwimCloud age group format
- Returns: `'0910'`, `'1112'`, `'1314'`, `'1516'`, or `'UNOV'`

### 4. Enhanced Request Interface

```typescript
interface ClubTeamsRequest {
  // Option 1: Use swimmer profile
  swimmer_id?: string // UUID - fetches age group, gender, region from profile
  
  // Option 2: Manual parameters (overrides profile if provided)
  ageGroup?: string // '0910', '1112', '1314', '1516', 'UNOV'
  gender?: 'M' | 'F'
  eventCourse?: 'Y' | 'L' // Y = Yards, L = Long Course
  region?: string // e.g., 'lsc_PN'
  seasonId?: number // Single season
  seasons?: number[] // Multiple seasons
  fetchAllPages?: boolean
}
```

## Usage Examples

### Example 1: Using Swimmer Profile
```json
{
  "swimmer_id": "uuid-of-swimmer",
  "eventCourse": "L" // Optional: override to Long Course
}
```
- Automatically gets age group from birth_date
- Automatically gets gender from swimmer record
- Uses default region (lsc_PN)

### Example 2: Manual Parameters
```json
{
  "ageGroup": "1314",
  "gender": "F",
  "eventCourse": "L",
  "region": "lsc_PN",
  "seasons": [29, 28, 27, 26]
}
```

### Example 3: Bulk Import (All Combinations)
```json
{
  "ageGroup": "1314",
  "gender": "F",
  "eventCourse": "L"
  // Will fetch for both Y and L, last 4 seasons
}
```

## API Endpoints Used

### 1. Team Rankings API
```
GET https://www.swimcloud.com/api/performances/top_rankings/
```
**Parameters**:
- `agegroup`: '0910', '1112', '1314', '1516', 'UNOV'
- `event_course`: 'Y' (Yards) or 'L' (Long Course Meters)
- `gender`: 'M' or 'F'
- `page`: Page number
- `region`: 'lsc_PN' (Pacific Northwest) or other LSC codes
- `season_id`: Season ID number
- `sort_by`: 'all' or 'top50'

**Response**:
```json
{
  "number": 1,
  "count": 43,
  "page_count": 1,
  "results": [
    {
      "id": 8019,
      "name": "Bellevue Club Swim Team",
      "location": "Bellevue, WA",
      "city": "Bellevue",
      "state": "WA",
      ...
    }
  ]
}
```

### 2. Season Choices API
```
GET https://www.swimcloud.com/api/seasonchoices/?count=10&from_next=false
```
**Response**:
```json
[
  {
    "seasonId": 29,
    "label": "2025-2026",
    "startDate": "2025-09-01",
    "endDate": "2026-08-31",
    "isCurrent": true
  },
  ...
]
```

## Age Group Calculation

Age groups are calculated from swimmer's `birth_date`:
- Age ≤ 10: `'0910'`
- Age ≤ 12: `'1112'`
- Age ≤ 14: `'1314'`
- Age ≤ 16: `'1516'`
- Age > 16: `'UNOV'` (Unlimited/Open)

## Region Support

Currently defaults to `'lsc_PN'` (Pacific Northwest). Can be overridden via `region` parameter.

Future enhancement: Store swimmer's LSC/region in database and use it automatically.

## Migration Notes

- Removed `DOMParser` dependency
- All HTML parsing logic removed
- Backward compatible: Still accepts URL parameter (extracts params from URL)
- Team IDs now properly extracted from API response
