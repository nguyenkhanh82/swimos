# Training Tab with Teams Management

## Overview

Transform the Training tab from a placeholder into a full-featured training management system with multi-team support, practice tracking, and filtering capabilities.

## Database Schema

### New Tables

1. **`teams`** - Team information
   - `id` (uuid, PK)
   - `name` (text, required)
   - `location` (text, nullable)
   - `team_type` (enum: 'regular', 'camp', 'private_coach', 'self')
   - `level` (text, nullable) - e.g., "Beginner", "Advanced", "Elite"
   - `created_by` (uuid, FK to auth.users)
   - `is_active` (boolean, default true)
   - `sportengines_id` (text, nullable) - for imported teams
   - `created_at`, `updated_at` (timestamps)

2. **`team_members`** - Many-to-many: Users ↔ Teams
   - `id` (uuid, PK)
   - `user_id` (uuid, FK to auth.users)
   - `team_id` (uuid, FK to teams)
   - `status` (enum: 'active', 'past')
   - `joined_date` (date)
   - `left_date` (date, nullable)
   - `role` (text, default 'swimmer') - for future coach/admin roles
   - `created_at`, `updated_at` (timestamps)
   - Unique constraint: (user_id, team_id)

3. **`coaches`** - Coach information
   - `id` (uuid, PK)
   - `name` (text, required)
   - `email` (text, nullable)
   - `phone` (text, nullable)
   - `created_by` (uuid, FK to auth.users) - who added this coach
   - `created_at`, `updated_at` (timestamps)

4. **`team_coaches`** - Many-to-many: Teams ↔ Coaches
   - `id` (uuid, PK)
   - `team_id` (uuid, FK to teams)
   - `coach_id` (uuid, FK to coaches)
   - `is_primary` (boolean, default false)
   - `created_at` (timestamp)

5. **`custom_tracked_events`** - User-defined events/strokes to track
   - `id` (uuid, PK)
   - `user_id` (uuid, FK to auth.users)
   - `team_id` (uuid, FK to teams, nullable) - team-specific or global
   - `event_name` (text, required) - e.g., "200 IM", "50 Fly"
   - `stroke` (text, nullable) - "Free", "Back", "Breast", "Fly", "IM"
   - `distance` (integer, nullable) - in meters/yards
   - `is_active` (boolean, default true)
   - `created_at`, `updated_at` (timestamps)

### Modified Tables

6. **`training_sets`** - Add team association
   - Add `team_id` (uuid, FK to teams, nullable) - nullable for backward compatibility
   - Add index on `team_id`

## Architecture

### Feature Structure

```
lib/src/features/training/
├── data/
│   ├── teams_repository.dart
│   ├── coaches_repository.dart
│   ├── training_repository.dart
│   └── custom_events_repository.dart
├── domain/
│   ├── team.dart
│   ├── team_member.dart
│   ├── coach.dart
│   ├── training_session.dart
│   └── custom_tracked_event.dart
├── application/
│   └── team_service.dart (business logic for team operations)
└── presentation/
    ├── training_screen.dart (main tab screen)
    ├── team_selection_sheet.dart (team picker)
    ├── team_management_screen.dart
    ├── create_team_screen.dart
    ├── import_team_screen.dart (SportEngines)
    ├── add_coach_dialog.dart
    ├── training_log_screen.dart
    ├── training_history_screen.dart
    └── filters/
        └── training_filters.dart
```

## Implementation Phases

### Phase 1: Core Team Management

1. **Database Migration**
   - Create all new tables with RLS policies
   - Add `team_id` to `training_sets`
   - Create indexes for performance

2. **Domain Models** (Freezed)
   - `Team`, `TeamMember`, `Coach`, `CustomTrackedEvent`
   - JSON serialization for Supabase

3. **Repositories**
   - `TeamsRepository` - CRUD for teams
   - `CoachesRepository` - CRUD for coaches
   - `TrainingRepository` - extend existing to support team filtering

4. **Team Management UI**
   - Team list/selection screen
   - Create team form (name, location, type, level)
   - Add/edit coaches dialog
   - Team member management (join/leave teams)

### Phase 2: Training Tracking with Teams

1. **Team Selection**
   - Bottom sheet or dropdown to select active team(s)
   - Show current active teams in header
   - Allow multiple team selection for practice logging

2. **Practice Logging**
   - Update training log form to include team selection
   - Link `training_sets` to selected team(s)
   - Support logging for multiple teams in one session

3. **Training History**
   - Display all practices with team badges
   - Filter by team, date range, stroke, distance
   - Group by team or chronological view

### Phase 3: Filtering & Custom Events

1. **Advanced Filtering**
   - Filter by: team, distance, stroke, IM, date range
   - Save filter presets
   - Quick filter chips

2. **Custom Events**
   - Create/edit custom events per team or globally
   - Track custom events in practice logs
   - Display in training history

### Phase 4: SportEngines Integration (Future)

1. **API Integration**
   - SportEngines API client
   - Team import flow
   - Sync team data

## Key Features

### Team Types

- **Regular**: Standard swim team
- **Camp**: Swim camp (temporary, date-based)
- **Private Coach**: Individual coaching
- **Self**: Personal training (no team)

### Team Selection Flow

1. User opens Training tab
2. If no teams exist → prompt to create/import
3. If teams exist → show team selector
4. User can select multiple active teams
5. When logging practice → associate with selected team(s)

### Training History Filters

- **Team**: Single or multiple team selection
- **Distance**: 50, 100, 200, 400, etc.
- **Stroke**: Free, Back, Breast, Fly, IM
- **Date Range**: Custom or presets (This Week, This Month, etc.)
- **Custom Events**: Filter by user-created events

## UI/UX Considerations

1. **Team Badge System**: Color-coded badges for different teams
2. **Quick Actions**: FAB for "Log Practice" with team pre-selection
3. **Empty States**: Helpful prompts when no teams/practices exist
4. **Swim Camp Indicator**: Special icon/badge for camp teams
5. **Coach Display**: Show coach names in team cards

## Database Migration File

Create: `supabase/migrations/YYYYMMDDHHMMSS_create_teams_and_training_tables.sql`

## Notes

- SportEngines API integration can be implemented later (Phase 4)
- Team levels are for display/organization only (no functional impact)
- Support backward compatibility: existing training_sets without team_id
- RLS policies ensure users only see their own teams and data

## Implementation Todos

1. Create database migration for teams, coaches, team_members, team_coaches, and custom_tracked_events tables with RLS policies
2. Create Freezed domain models: Team, TeamMember, Coach, CustomTrackedEvent with JSON serialization
3. Implement repositories: TeamsRepository, CoachesRepository, extend TrainingRepository for team support
4. Build team management screens: team list, create team form, add coach dialog, team member management
5. Implement team selection UI (bottom sheet/dropdown) with multi-team support
6. Update training log form to include team selection and link training_sets to teams
7. Build training history screen with team badges and filtering (team, distance, stroke, date)
8. Implement custom events creation and tracking in practice logs
9. Add advanced filtering UI with filter chips and saved presets
