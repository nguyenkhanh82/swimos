# SwimTrack Pro - Mobile App

A Flutter-based mobile application for SwimTrack Pro, allowing swimmers to track meets, times, and training goals.

## Features
- **Dashboard**: Quick stats, upcoming meets, and recent activity.
- **Meets**: View upcoming and past meets, add new meets, and manage event entries.
- **Authentication**: Sign up/login via email (Supabase Auth).

## Tech Stack
- Flutter
- Riverpod (State Management)
- Supabase (Backend: Auth & Database)
- GoRouter (Navigation)

## Getting Started

1. Ensure you have Flutter installed.
2. Create a `.env` file in the root with your Supabase credentials:
   ```
   VITE_SUPABASE_URL=your_url
   VITE_SUPABASE_PUBLISHABLE_KEY=your_key
   ```
3. Run the app:
   ```bash
   flutter run -d chrome
   ```

## Testing

### Integration Tests
This project includes end-to-end integration tests to verify critical flows like Account Creation, Login, and Account Deletion.

**Prerequisites:**
- `chromedriver` must be installed.
  ```bash
  brew install --cask chromedriver
  # Start chromedriver on port 4444
  chromedriver --port=4444
  ```

**Running the Test:**
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```
