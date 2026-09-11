
# 🚀 Ultimate AI Prompt: SwimTrack Pro (Flutter + Supabase Edition)

**Context**: You are an expert Flutter Engineer & UI Designer. You are building "SwimTrack Pro", a high-performance, aesthetically stunning Mobile App for competitive swimmers.

**Mission**: Generate a complete, compilable, and architecturally sound Flutter project using **Supabase**. Do not hallucinate packages.

---

## 🛠 1. Tech Stack & Architecture (Strict Guidelines)

*   **Framework**: Flutter (Latest Stable).
*   **Architecture**: Feature-First (Layered) Architecture.
    *   `lib/src/features/` (auth, meets, training, nutrition)
    *   `lib/src/common_widgets/`
    *   `lib/src/constants/`
    *   `lib/src/routing/`
*   **State Management**: **Riverpod** (Generator syntax `@riverpod`). Use `AsyncValue` for all data fetching.
*   **Data Classes**: **Freezed** & **JsonSerializable** (Immutable state).
*   **Backend**: **Supabase** (PostgreSQL, Supabase Auth).
    *   Packages: `supabase_flutter`.
*   **Navigation**: **GoRouter** (Typed routes).
*   **UI/Styling**:
    *   **Glassmorphism**: Heavy use of `BackdropFilter`, semi-transparent gradients (`Colors.white.withOpacity(0.1)`), and `BoxShadow`.
    *   **Fonts**: `GoogleFonts.outfit()` (Headers), `GoogleFonts.spaceGrotesk()` (Data).
    *   **Charts**: `fl_chart`.

---

## 📂 2. File Structure

Establish this exact directory structure:

```
lib/
├── src/
│   ├── app.dart                  # Main App Widget (Riverpod Scope, GoRouter config)
│   ├── features/
│   │   ├── authentication/
│   │   │   ├── data/             # AuthRepository (Supabase Auth)
│   │   │   └── presentation/     # LoginScreen (Glass style)
│   │   ├── meets/
│   │   │   ├── data/             # MeetsRepository (Supabase Client)
│   │   │   ├── domain/           # Meet, SwimTime, TimeStandard (Freezed models)
│   │   │   ├── application/      # StandardsAnalysisService (The "Brain")
│   │   │   └── presentation/     # MeetsListScreen, MeetDetailScreen
│   │   ├── training/             # TrainingLogScreen
│   │   └── nutrition/            # MealPlanScreen
│   └── routing/
│       └── app_router.dart
└── main.dart                     # Supabase.initialize()
```

---

## 💾 3. Data Models & Database Schema (PostgreSQL)

**Tables**:

1.  **`profiles`**:
    *   `id` (uuid, PK, refs auth.users)
    *   `full_name`, `avatar_url`, `role`, `team_name`, `primary_stroke`.

2.  **`swim_meets`**:
    *   `id` (uuid, PK)
    *   `user_id` (uuid, FK)
    *   `meet_name`, `start_date`, `end_date`, `location`, `pool_type` ('SCY', 'LCM').

3.  **`meet_entries`**:
    *   `id` (uuid, PK)
    *   `meet_id` (uuid, FK)
    *   `event_name`, `seed_time_seconds`.

4.  **`swim_times`** (Results):
    *   `id` (uuid, PK)
    *   `meet_id` (uuid, FK)
    *   `event_name`, `time_seconds`, `is_personal_best`, `date`.

5.  **`time_standards`** (Reference Data):
    *   `id` (uuid, PK)
    *   `gender`, `age_group`, `event_name`, `course`
    *   `standard_name` ('A', 'AA', 'AAA', etc.)
    *   `time_seconds`.

**Dart Models (Freezed)**
*   Generate `Meet`, `MeetEntry`, `SwimTime`, `TimeStandard` with `fromJson`/`toJson` compatible with Supabase response maps.

---

## 🧠 4. Core Business Logic: "Standards Analysis Engine"

You must implement a Service class: `StandardsService`.

**Logic**:
1.  **Input**: Swimmer's time (`54.50s`), Gender ("M"), Age ("12"), Event ("100 Free").
2.  **Process**:
    *   Query `time_standards` table where `event_name == "100 Free"` AND `age_group == "11-12"` AND `gender == "M"`.
    *   **Sort** results by time.
    *   **Identify Achieved**: The standard with `standard.time >= swimmer.time`.
    *   **Identify Next Cut**: The next standard with `standard.time < swimmer.time`.
3.  **Output**: A `SwimAnalysis` object containing:
    *   `Badge? achievedBadge` (e.g. "AA")
    *   `double progressPercent` (0.0 to 1.0).

---

## 🎨 5. UI/UX Specifications (Glassmorphism)

**Card Style**:
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
  ),
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: ...)
)
```

**Features**:
*   **Login Screen**: Glass card form, "Sign in with Email" (Supabase Magic Link or Password).
*   **Meet Details**: Cards for each event. Expansion tile reveals the "Next Cut" progress bar.
*   **Offline Mode**: Handle connectivity gracefully (Supabase caching or local storage).

---

## 📝 6. Feature Specifications Update

*   **Auth**: Switch to `Supabase Auth`.
*   **Database**: Use Postgres Row Level Security (RLS) policies for data safety.
*   **Standards Seeding**: A script or function to `upsert` the 2025-2028 JSON standards into the `time_standards` table on app launch if empty.

---

## 🏗 7. Architecture Decision Records (ADR) - Guidelines

*   **Mobile Framework**: Flutter.
*   **Backend**: Supabase (Postgres).
*   **State Management**: Riverpod.
*   **Navigation**: GoRouter.

---

## 🚀 8. Execution Instructions (The Prompt)

**Copy this prompt into your AI builder:**

> "Generate a comprehensive **Flutter** project for 'SwimTrack Pro'.
>
> **Stack**: Flutter 3.x, **Riverpod** (AsyncNotifier), **GoRouter**, **Supabase** (`supabase_flutter`).
>
> **Requirements**:
> 1. **Setup**: Config `supabase_flutter` in `main.dart`. Create feature folders (`lib/src/features/...`).
> 2. **Auth**: Login Screen with Glassmorphism UI. Use Supabase Auth.
> 3. **Data**: Setup repositories using Supabase Client. Models: `Meet`, `SwimTime`, `TimeStandard` (Freezed).
> 4. **Logic**: Implement `StandardsAnalysisService`. It queries the `time_standards` table.
> 5. **UI**: Build `MeetDetailScreen` (Expandable event cards with Standard Badges/Progress Bars).
> 6. **Seeding**: Include a `seedStandards()` function that writes a hardcoded list of USA Swimming 2025 standards to the `time_standards` table if empty.
> 7. **Styling**: Deep Blue/Cyan palette. Modern Sports Aesthetics (Google Fonts Outfit/Space Grotesk).
>
> **Refer to the detailed specifications above for exact Schema and Business Logic.**"
