# Team Search Architecture

## Overview

The team search functionality allows users to find and join existing teams that were imported from SwimCloud when creating a new "Regular" team.

## Architecture Flow

```
User Types Team Name
    ↓
CreateTeamScreen._onSearchChanged()
    ↓
TeamsRepository.searchTeams(query)
    ↓
Supabase Query (with RLS policies)
    ↓
Filter: team_type='regular' AND sportengines_id IS NOT NULL AND is_active=true
    ↓
Return Results → Display in UI
```

## Database Schema

### Teams Table
- `id` (UUID, PK)
- `name` (TEXT, required)
- `team_type` (ENUM: 'regular', 'camp', 'private_coach', 'self')
- `sportengines_id` (TEXT, nullable) - **Deprecated**: Not used, kept for backward compatibility
- `is_active` (BOOLEAN, default true)
- `created_by` (UUID, FK to auth.users)
- `location` (TEXT, nullable)

## Row Level Security (RLS) Policies

### Original Policy (Restrictive)
```sql
CREATE POLICY "Users can view teams they created or are members of"
  FOR SELECT USING (
    created_by = auth.uid() OR
    id IN (SELECT team_id FROM public.team_members WHERE user_id = auth.uid())
  );
```

**Problem**: This blocked access to imported teams (sportengines_id IS NOT NULL) that users didn't create.

### New Policy (Added)
```sql
CREATE POLICY "Users can view imported teams (for search)"
  FOR SELECT USING (
    sportengines_id IS NOT NULL AND
    team_type = 'regular' AND
    is_active = true
  );
```

**Solution**: Allows public read access to imported regular teams for search functionality.

## Search Query Logic

```dart
Future<List<Team>> searchTeams(String query) async {
  return await _supabase
    .from('teams')
    .select()
    .eq('team_type', 'regular')           // Only regular teams
    // All regular teams are considered imported teams
    .ilike('name', '%$query%')            // Case-insensitive name match
    .eq('is_active', true)                // Only active teams
    .limit(20)
    .order('name', ascending: true);
}
```

## Key Components

### 1. TeamsRepository (`lib/src/features/training/data/teams_repository.dart`)
- `searchTeams()`: Performs the database query with filters
- Includes comprehensive debug logging

### 2. CreateTeamScreen (`lib/src/features/training/presentation/create_team_screen.dart`)
- Shows search field only when `team_type == TeamType.regular`
- Real-time search with 300ms debounce
- Displays results in scrollable list
- Allows selecting existing team or creating new one

## Debug Logging

Both components include extensive debug logging:
- Query parameters
- Result counts
- Sample data
- Error messages with stack traces

Check console output for:
- `[TeamsRepository]` - Database query logs
- `[CreateTeamScreen]` - UI interaction logs

## Common Issues & Solutions

### Issue: No teams found
**Possible causes:**
1. **RLS Policy**: Ensure the new policy is applied (migration `20260125000009`)
2. **No imported teams**: Run `fetch-club-teams` function to import teams
3. **team_type mismatch**: Teams must be `team_type='regular'`
4. **team_type mismatch**: Teams must be `team_type='regular'`
5. **is_active=false**: Teams must be active

### Issue: Search returns empty but teams exist
**Check:**
- Are teams imported from SwimCloud? (have `sportengines_id`)
- Are teams `team_type='regular'`?
- Are teams `is_active=true`?
- Check RLS policies are correctly applied

## Testing

1. **Import teams**: Run `fetch-club-teams` Edge Function
2. **Verify import**: Check database has teams with `team_type='regular'`
3. **Test search**: Type team name in Create Team screen
4. **Check logs**: Review console output for debug information

## Future Enhancements

- Add location-based filtering
- Add pagination for large result sets
- Cache search results
- Add team preview/details before joining
