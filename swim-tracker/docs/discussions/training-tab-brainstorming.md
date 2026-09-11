# Training Tab Brainstorming Session

**Date**: January 11, 2025  
**Feature**: Training Tab with Teams Management

## Requirements Discussion

### Core Concept
The Training tab needs to support swimmers who may be part of multiple teams simultaneously (e.g., school team, club team, swim camps). The system should allow flexible team management and practice tracking per team.

### Key Requirements Identified

#### 1. Multiple Teams Support
- Swimmers can have multiple teams (past and current)
- Can be in multiple teams simultaneously
- Teams can be:
  - Self-created
  - Imported from SportEngines
  - Used for private coaching
  - Personal training (self)

#### 2. Team Creation & Management
- **Team Information**:
  - Team name
  - Location
  - Coaches (multiple coaches per team)
  - Level (for organization/display purposes)
  
- **Team Types**:
  - Regular team
  - Swim camp (temporary, date-based)
  - Private coach
  - Self (personal training)

#### 3. Team Selection & Tracking
- Swimmer selects which team(s) to track for
- Can track practices for multiple teams
- Training history filtered by selected team(s)

#### 4. Practice Tracking
- Log practice sessions
- View training history
- Filter by:
  - Distance (50, 100, 200, etc.)
  - Stroke (Free, Back, Breast, Fly)
  - Individual Medley (IM)
- Create custom events/strokes to track

#### 5. Swim Camps
- Special handling for swim camps
- Track camp participation
- Associate practices with camps

## Decisions Made

### Team Relationship Model
**Decision**: Multiple active teams - swimmers can track practices for different teams on different days simultaneously.

**Rationale**: Swimmers often train with multiple teams (school + club) and need to track practices for each separately.

### SportEngines Integration
**Decision**: API integration (Phase 4 - Future implementation)

**Rationale**: Allows for automated team import, but can start with manual team creation first.

### Team Levels
**Decision**: Levels are for display/organization only - no functional impact on tracking.

**Rationale**: Keeps the system flexible - levels are informational (e.g., "Beginner", "Advanced", "Elite") but don't change what metrics are tracked.

### Swim Camps
**Decision**: Camps are a special type of team (team_type: 'camp')

**Rationale**: Simplifies the data model - camps are just teams with a different type flag and can have date ranges.

## Open Questions / Future Considerations

1. **Team Sharing**: Should teams be shareable between users (e.g., multiple swimmers on same team)?
2. **Coach Accounts**: Should coaches have their own accounts to manage teams?
3. **Team Analytics**: Should there be team-level analytics/statistics?
4. **Practice Templates**: Should teams be able to create practice templates?
5. **Notifications**: Should swimmers get notifications for team practices?

## Next Steps

1. Review and approve the implementation plan
2. Begin Phase 1: Database migration and core team management
3. Research SportEngines API for future integration
