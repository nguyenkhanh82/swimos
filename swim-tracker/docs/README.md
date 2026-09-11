# SwimTrack Pro - Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [System Design](#system-design)
4. [Architecture Decision Records (ADR)](#architecture-decision-records)
5. [Database Schema](#database-schema)
6. [API Reference](#api-reference)

## Documentation Structure

- **Plans**: Implementation plans for features (`docs/plans/`)
  - [Master App Plan](./plans/master-app-plan.md) - Complete app roadmap with acceptance criteria
  - [Training Tab Plan](./plans/training-tab-teams-management.md) - Teams & training feature plan

- **Discussions**: Brainstorming and decision notes (`docs/discussions/`)
  - [Training Tab Brainstorming](./discussions/training-tab-brainstorming.md)

- **Integrations**: Third-party integration research (`docs/integrations/`)

---

## Overview

SwimTrack Pro is a comprehensive swim training and nutrition tracking application designed for competitive swimmers. The app helps athletes track their swim times, manage meets, monitor nutrition, and visualize progress over time.

### Tech Stack
- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend & Database**: Supabase (PostgreSQL, Auth, Edge Functions)
- **Navigation**: GoRouter
- **Charts**: fl_chart
- **Animations**: Flutter Animate
- **AI Integration**: Supabase Edge Functions + Google Gemini

---

## Features

### 1. Authentication & User Management
- Email/password authentication via Supabase Auth
- User profiles with swimmer details (team, coach, primary stroke)
- Protected routes requiring authentication

### 2. Swim Times Tracking
- **Add Times**: Record swim times with event, distance, stroke, pool type
- **Personal Bests**: Automatic PR detection using Postgres Triggers
- **Time History**: View all recorded times with filtering by stroke
- **Delete Times**: Remove incorrect entries

### 3. Personal Records Wall
- Visual display of all-time best times per event
- Medal/badge system (gold, silver, bronze for top 3)
- Meet and date information for each PR

### 4. Time Improvement Tracking
- Percentage improvement calculation (first vs latest time)
- Visual progress bars
- Best time tracking per event
- Sorted by improvement magnitude

### 5. Time Converter
- Convert times between pool types:
  - SCY (Short Course Yards)
  - SCM (Short Course Meters)
  - LCM (Long Course Meters)
- USA Swimming-based conversion factors
- Support for all standard distances

### 6. Swim Meets Management
- **Create Meets**: Add upcoming competitions with dates and location
- **Meet Entries**: Track events entered for each meet
- **Seed Times**: Record expected times
- **Results**: Log final times and placements
- **Meet Status**: Upcoming, In Progress, Completed

### 7. Nutrition Tracking
- **Daily Logging**: Record meals with calories and macros
- **Nutrition Goals**: Set daily calorie/protein/carb/fat targets
- **Progress Visualization**: Charts showing goal progress
- **Weekly Trends**: Track nutrition patterns over time

### 8. AI-Powered Meal Planning
- Generate personalized weekly meal plans (Supabase Edge Function)
- Based on nutrition goals and preferences
- Day-by-day meal suggestions
- Macro-optimized recommendations

### 9. Race Plan Generation
- AI-generated race strategies
- Based on target times and events
- Pacing recommendations
- Pre-race preparation tips

### 10. Dashboard & Analytics
- **Quick Stats**: Total times, PRs, upcoming meets
- **Training Progress Chart**: Average vs best times by event
- **Training Volume Chart**: Weekly distance over past month
- **Goal Progress**: Visual progress toward time goals
- **Weekly Nutrition Chart**: Daily macro trends

### 11. Goal Setting
- Set target times for specific events
- Track progress toward goals
- Visual goal progress indicators

### 12. Mobile Experience
- **Native Performance**: 60fps animations
- **Offline Support**: Local caching (Hive or shared_preferences)
- **Touch-optimized**: Native gestures and navigation

---

## System Design

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client (Mobile)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Flutter   │  │  Riverpod   │  │   GoRouter          │  │
│  │   UI        │  │  State      │  │   Navigation        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Cloud                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Auth      │  │  Postgres   │  │   Edge Functions   │  │
│  │   (JWT)     │  │  Database   │  │   (Deno)           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                              │               │
│                                              ▼               │
│                                    ┌─────────────────────┐  │
│                                    │   Google Gemini     │  │
│                                    │   (AI Models)       │  │
│                                    └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
lib/
├── src/
│   ├── app.dart                  # Main App Widget
│   ├── features/                 # Modular Features
│   │   ├── auth/                 
│   │   │   ├── data/             # Repositories (Supabase Client)
│   │   │   └── presentation/     
│   │   ├── meets/                
│   │   │   ├── data/             # MeetsRepository
│   │   │   ├── domain/           # Models (Freezed)
│   │   │   └── presentation/     
│   │   ├── training/             
│   │   └── nutrition/            
│   ├── common_widgets/           # Shared UI components
│   ├── constants/                # App-wide constants
│   ├── routing/                  # GoRouter configuration
│   └── utils/                    # Helper functions
└── main.dart                     # Entry point
```

### Data Flow

1. **Authentication Flow**
   ```
   User → Auth Screen → Supabase Auth → Session → Protected Routes
   ```

2. **Data Fetching Flow**
   ```
   UI → Riverpod Provider → Repository → Supabase SDK → Postgres
   ```

3. **AI Generation Flow**
   ```
   User Input → Edge Function → Gemini API → Response → UI
   ```

### State Management Strategy

- **App State**: Riverpod (AsyncNotifier)
- **Data Persistence**: Supabase Realtime + Local Caching
- **Immutable Models**: Freezed + JsonSerializable

---

## Architecture Decision Records

### ADR-001: Frontend Framework Selection
**Status**: Accepted  
**Date**: 2026-01

**Context**: Need a high-performance cross-platform mobile application.

**Decision**: Flutter.

**Rationale**:
- Single codebase for iOS and Android
- "Hot Reload" for rapid development
- High-performance Skia/Impeller rendering engine
- Strong typing with Dart

**Consequences**:
- Positive: Native-like performance, unified dev team
- Negative: UI components need to be built or adapted (Glassmorphism)

---

### ADR-002: Backend Architecture
**Status**: Accepted  
**Date**: 2024-01

**Context**: Need a scalable backend with authentication, database, and serverless functions.

**Decision**: Supabase.

**Rationale**:
- Integrated PostgreSQL database (Relational)
- Built-in authentication
- Edge functions for serverless logic
- Real-time capabilities
- Row Level Security (RLS) for data protection

**Consequences**:
- Positive: Rapid development, built-in security, SQL power
- Negative: none significantly compared to alternatives

---

### ADR-003: State Management
**Status**: Accepted  
**Date**: 2026-01

**Context**: Need efficient state management for server and client state.

**Decision**: Riverpod.

**Rationale**:
- Compile-time safety
- Excellent testing support
- Explicit dependency injection
- Built-in async handling (AsyncValue)

---

## Database Schema (PostgreSQL)

### Tables Overview

| Table | Description |
|-------|-------------|
| `profiles` | User profile information |
| `swim_times` | Recorded swim times |
| `swim_meets` | Competition information |
| `meet_entries` | Events entered per meet |
| `time_standards` | USA Swimming Standards (Reference) |
| `nutrition_logs` | Daily meal records |

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│    profiles     │       │   swim_times    │
├─────────────────┤       ├─────────────────┤
│ id (PK, uuid)   │       │ id (PK)         │
│ user_id (FK)    │◄──────│ user_id (FK)    │
│ full_name       │       │ event_name      │
│ team_name       │       │ time_seconds    │
│ primary_stroke  │       │ is_personal_best│
└─────────────────┘       └─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│   swim_meets    │       │  meet_entries   │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ meet_id (FK)    │
│ user_id (FK)    │       │ event_name      │
│ meet_name       │       │ seed_time       │
│ start_date      │       └─────────────────┘
└───┬─────────────┘
    │
    │ (One-to-Many)
    ▼
┌─────────────────┐       ┌─────────────────┐
│ time_standards  │       │ nutrition_logs  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ gender, age     │       │ user_id (FK)    │
│ event, time     │       │ calories, macros│
│ standard_name   │       │ date            │
└─────────────────┘       └─────────────────┘
```

┌─────────────────┐
│   meal_plans    │
├─────────────────┤
│ id (PK)         │
│ user_id (FK)    │
│ day_of_week     │
│ meal_type       │
│ meal_name       │
│ description     │
│ calories        │
│ protein_grams   │
│ carbs_grams     │
│ fat_grams       │
└─────────────────┘
```

---

## API Reference

### Base URL

```
https://kuwotiliouajfdjejsny.supabase.co/functions/v1
```

### Authentication

All endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer <JWT_TOKEN>
```

---

## OpenAPI Specification

```yaml
openapi: 3.0.3
info:
  title: SwimTrack Pro API
  description: |
    API for SwimTrack Pro swimming training application.
    Provides AI-powered meal planning and race strategy generation.
  version: 1.0.0
  contact:
    name: SwimTrack Pro Support
  license:
    name: MIT

servers:
  - url: https://kuwotiliouajfdjejsny.supabase.co/functions/v1
    description: Production server

tags:
  - name: AI Generation
    description: AI-powered content generation endpoints
  - name: Meal Planning
    description: Nutrition and meal plan generation
  - name: Race Planning
    description: Race strategy and pacing generation

paths:
  /generate-meal-plan:
    post:
      operationId: generateMealPlan
      summary: Generate AI meal plan
      description: |
        Generates a personalized weekly meal plan using AI based on 
        the user's nutrition goals. Returns 28 meals (4 per day for 7 days).
      tags:
        - AI Generation
        - Meal Planning
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/MealPlanRequest'
            examples:
              swimmer:
                summary: Active Swimmer
                value:
                  goals:
                    daily_calories: 3000
                    daily_protein_grams: 180
                    daily_carbs_grams: 350
                    daily_fat_grams: 90
              maintenance:
                summary: Maintenance Diet
                value:
                  goals:
                    daily_calories: 2200
                    daily_protein_grams: 120
                    daily_carbs_grams: 250
                    daily_fat_grams: 70
      responses:
        '200':
          description: Successfully generated meal plan
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/MealPlanResponse'
        '400':
          description: Invalid request body
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Invalid or missing JWT token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '402':
          description: Payment Required - AI credits exhausted
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "AI usage limit reached. Please add credits."
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "Rate limits exceeded. Please try again later."
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
    options:
      operationId: mealPlanCors
      summary: CORS preflight
      description: Handles CORS preflight requests
      responses:
        '200':
          description: CORS headers returned

  /generate-race-plan:
    post:
      operationId: generateRacePlan
      summary: Generate AI race strategy
      description: |
        Generates a detailed race plan and pacing strategy using AI.
        Includes pre-race preparation, split times, technique focus points,
        and mental cues based on the target event and swimmer's personal bests.
      tags:
        - AI Generation
        - Race Planning
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/RacePlanRequest'
            examples:
              sprint:
                summary: 50m Freestyle Sprint
                value:
                  event: "50 Freestyle"
                  distance: 50
                  targetTime: 25.5
                  poolType: "LCM"
                  personalBests:
                    - event_name: "50 Freestyle"
                      time_seconds: 26.2
                    - event_name: "100 Freestyle"
                      time_seconds: 57.8
              distance:
                summary: 400m Individual Medley
                value:
                  event: "400 IM"
                  distance: 400
                  targetTime: 285.0
                  poolType: "LCM"
                  personalBests:
                    - event_name: "100 Butterfly"
                      time_seconds: 62.5
                    - event_name: "100 Backstroke"
                      time_seconds: 65.0
                    - event_name: "100 Breaststroke"
                      time_seconds: 72.0
                    - event_name: "100 Freestyle"
                      time_seconds: 58.0
      responses:
        '200':
          description: Successfully generated race plan
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RacePlanResponse'
        '400':
          description: Invalid request body
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Invalid or missing JWT token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '402':
          description: Payment Required - AI credits exhausted
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "AI credits exhausted. Please add credits to continue."
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error: "Rate limit exceeded. Please try again in a moment."
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
    options:
      operationId: racePlanCors
      summary: CORS preflight
      description: Handles CORS preflight requests
      responses:
        '200':
          description: CORS headers returned

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: Supabase JWT token from authenticated session

  schemas:
    # Request Schemas
    MealPlanRequest:
      type: object
      required:
        - goals
      properties:
        goals:
          $ref: '#/components/schemas/NutritionGoals'

    NutritionGoals:
      type: object
      required:
        - daily_calories
        - daily_protein_grams
        - daily_carbs_grams
        - daily_fat_grams
      properties:
        daily_calories:
          type: integer
          minimum: 1000
          maximum: 10000
          description: Target daily calorie intake
          example: 2500
        daily_protein_grams:
          type: number
          minimum: 0
          maximum: 500
          description: Target daily protein in grams
          example: 150
        daily_carbs_grams:
          type: number
          minimum: 0
          maximum: 800
          description: Target daily carbohydrates in grams
          example: 300
        daily_fat_grams:
          type: number
          minimum: 0
          maximum: 300
          description: Target daily fat in grams
          example: 80

    RacePlanRequest:
      type: object
      required:
        - event
        - distance
        - targetTime
        - poolType
      properties:
        event:
          type: string
          description: Event name (e.g., "200 Freestyle", "100 Butterfly")
          example: "200 Freestyle"
        distance:
          type: integer
          enum: [50, 100, 200, 400, 800, 1500]
          description: Race distance in meters
          example: 200
        targetTime:
          type: number
          description: Target time in seconds
          example: 115.5
        poolType:
          type: string
          enum: [SCY, SCM, LCM]
          description: |
            Pool type:
            - SCY: Short Course Yards (25 yards)
            - SCM: Short Course Meters (25 meters)
            - LCM: Long Course Meters (50 meters)
          example: "LCM"
        personalBests:
          type: array
          items:
            $ref: '#/components/schemas/SwimTime'
          description: Swimmer's personal best times for context
          default: []

    SwimTime:
      type: object
      required:
        - event_name
        - time_seconds
      properties:
        event_name:
          type: string
          description: Event name
          example: "100 Freestyle"
        time_seconds:
          type: number
          description: Time in seconds
          example: 54.32

    # Response Schemas
    MealPlanResponse:
      type: object
      required:
        - meals
      properties:
        meals:
          type: array
          items:
            $ref: '#/components/schemas/Meal'
          description: Array of 28 meals (4 per day for 7 days)
          minItems: 28
          maxItems: 28

    Meal:
      type: object
      required:
        - day_of_week
        - meal_type
        - meal_name
        - calories
        - protein_grams
        - carbs_grams
        - fat_grams
      properties:
        day_of_week:
          type: integer
          minimum: 0
          maximum: 6
          description: Day of week (0=Sunday, 6=Saturday)
          example: 0
        meal_type:
          type: string
          enum: [breakfast, lunch, dinner, snack]
          description: Type of meal
          example: "breakfast"
        meal_name:
          type: string
          description: Name/title of the meal
          example: "Protein Oatmeal Bowl"
        description:
          type: string
          nullable: true
          description: Brief description with key ingredients
          example: "Steel-cut oats with whey protein, banana, and almonds"
        calories:
          type: integer
          minimum: 0
          description: Estimated calories
          example: 450
        protein_grams:
          type: number
          minimum: 0
          description: Protein content in grams
          example: 35
        carbs_grams:
          type: number
          minimum: 0
          description: Carbohydrate content in grams
          example: 55
        fat_grams:
          type: number
          minimum: 0
          description: Fat content in grams
          example: 12

    RacePlanResponse:
      type: object
      required:
        - racePlan
      properties:
        racePlan:
          type: string
          description: |
            Markdown-formatted race plan including:
            - Pre-Race Preparation
            - Race Strategy with split times
            - Technical Focus Points
            - Energy Management
            - Common Mistakes to Avoid
            - Mental Cues
          example: |
            ## Pre-Race Preparation
            
            ### Warm-up Routine
            - 400m easy swim...

    ErrorResponse:
      type: object
      required:
        - error
      properties:
        error:
          type: string
          description: Error message
          example: "Invalid request parameters"
```

---

## Edge Function Details

### `generate-meal-plan`

Generates a personalized weekly meal plan using the Lovable AI (Gemini 2.5 Flash model).

**Authentication**: Required (JWT)

**Rate Limits**: Standard Lovable AI rate limits apply

**Request Example (cURL)**:
```bash
curl -X POST \
  'https://kuwotiliouajfdjejsny.supabase.co/functions/v1/generate-meal-plan' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "goals": {
      "daily_calories": 2500,
      "daily_protein_grams": 150,
      "daily_carbs_grams": 300,
      "daily_fat_grams": 80
    }
  }'
```

**Response Example**:
```json
{
  "meals": [
    {
      "day_of_week": 0,
      "meal_type": "breakfast",
      "meal_name": "Protein Oatmeal",
      "description": "Oats with protein powder, banana, and almonds",
      "calories": 450,
      "protein_grams": 35,
      "carbs_grams": 55,
      "fat_grams": 10
    },
    {
      "day_of_week": 0,
      "meal_type": "lunch",
      "meal_name": "Grilled Chicken Salad",
      "description": "Mixed greens with grilled chicken, quinoa, and avocado",
      "calories": 580,
      "protein_grams": 45,
      "carbs_grams": 40,
      "fat_grams": 22
    }
  ]
}
```

---

### `generate-race-plan`

Generates a detailed race strategy and pacing plan using the Lovable AI (Gemini 2.5 Flash model).

**Authentication**: Required (JWT)

**Rate Limits**: Standard Lovable AI rate limits apply

**Request Example (cURL)**:
```bash
curl -X POST \
  'https://kuwotiliouajfdjejsny.supabase.co/functions/v1/generate-race-plan' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "event": "200 Freestyle",
    "distance": 200,
    "targetTime": 115.5,
    "poolType": "LCM",
    "personalBests": [
      {"event_name": "100 Freestyle", "time_seconds": 54.2},
      {"event_name": "50 Freestyle", "time_seconds": 24.8}
    ]
  }'
```

**Response Example**:
```json
{
  "racePlan": "## Pre-Race Preparation\n\n### Warm-up Routine\n- 400m easy swim mixing strokes\n- 4x50m build to race pace with :15 rest\n- 4x25m race pace starts\n\n### Mental Preparation\n- Visualize each 50m split\n- Focus on your breathing pattern\n\n## Race Strategy\n\n### Split Times for 1:55.50 Target\n| Split | Time | Cumulative | Pace Notes |\n|-------|------|------------|------------|\n| 50m | 27.0 | 0:27.0 | Strong start, settle into rhythm |\n| 100m | 28.5 | 0:55.5 | Maintain stroke count |\n| 150m | 29.0 | 1:24.5 | Hold form, breathe every 3 |\n| 200m | 31.0 | 1:55.5 | Build to finish, sprint last 15m |\n\n..."
}
```

---

## Security Considerations

### Row Level Security (RLS)
All tables have RLS enabled with user-scoped policies:
- Users can only SELECT their own data
- Users can only INSERT with their own user_id
- Users can only UPDATE their own records
- Users can only DELETE their own records

### Authentication
- JWT tokens with short expiry
- Auto-confirm disabled in production
- Session management via Supabase Auth

### Data Protection
- No PII exposed in client-side code
- Secure environment variables
- HTTPS-only communication

### API Security
- CORS headers restrict origin access
- Rate limiting prevents abuse
- JWT validation on all protected endpoints

---

## Performance Considerations

### Client-Side
- Code splitting via React Router
- Lazy loading for non-critical routes
- Optimistic updates for better UX
- Skeleton loading states

### Server-Side
- Edge functions for low latency
- Database indexes on frequently queried columns
- Connection pooling via Supabase

### Caching
- React Query cache with stale-while-revalidate
- Service worker for PWA caching

---

## Error Handling

### Error Codes

| HTTP Code | Description | Action |
|-----------|-------------|--------|
| 400 | Invalid request body | Check request format |
| 401 | Unauthorized | Re-authenticate user |
| 402 | Payment Required | Add AI credits |
| 429 | Rate Limited | Wait and retry |
| 500 | Server Error | Check logs, retry |

### Retry Strategy

For transient errors (429, 500), implement exponential backoff:

```typescript
const retryWithBackoff = async (fn, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(r => setTimeout(r, Math.pow(2, i) * 1000));
    }
  }
};
```

---

## Future Improvements

1. **Social Features**: Team workouts, coach assignments
2. **Video Analysis**: Upload and analyze swim technique
3. **Wearable Integration**: Sync with swim watches
4. **Advanced Analytics**: ML-based performance predictions
5. **Offline Mode**: Full offline capability with sync
6. **Multi-language**: Internationalization support
7. **GraphQL API**: Alternative query interface
8. **Webhook Support**: Real-time event notifications
