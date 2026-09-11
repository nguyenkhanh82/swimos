# Phase 1: Goal Detail & Manual Progress - Troubleshooting Guide

## Quick Diagnostics

Run this checklist first:
- [ ] Database migration applied
- [ ] App built successfully (`flutter build ios --debug --no-codesign`)
- [ ] At least one goal exists in the database
- [ ] User is logged in

---

## Common Issues & Solutions

### 1. "relation 'goal_progress_entries' does not exist"

**Symptoms**:
- Error when viewing custom goal details
- Error when trying to add progress
- Console shows: `PostgrestException: relation "public.goal_progress_entries" does not exist`

**Cause**: Database migration not applied

**Solution**:
Go to Supabase Dashboard → SQL Editor → New Query, paste and run:

```sql
-- Create goal_progress_entries table for manual progress tracking
CREATE TABLE public.goal_progress_entries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  goal_id UUID NOT NULL REFERENCES public.training_goals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  progress_value DECIMAL(10, 2) NOT NULL,
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_goal_progress_entries_goal_id ON public.goal_progress_entries(goal_id);
CREATE INDEX idx_goal_progress_entries_user_id ON public.goal_progress_entries(user_id);
CREATE INDEX idx_goal_progress_entries_recorded_at ON public.goal_progress_entries(recorded_at DESC);

-- RLS Policies
ALTER TABLE public.goal_progress_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own progress entries"
ON public.goal_progress_entries FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own progress entries"
ON public.goal_progress_entries FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress entries"
ON public.goal_progress_entries FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own progress entries"
ON public.goal_progress_entries FOR DELETE
USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_goal_progress_entries_updated_at
BEFORE UPDATE ON public.goal_progress_entries
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
```

---

### 2. "Goal not found" when clicking goal

**Symptoms**: Blank screen or "Goal not found" message

**Possible Causes**:
1. Goal was deleted
2. User doesn't have permission (RLS issue)
3. Navigation issue

**Solution**:
```dart
// Check Supabase Dashboard → Table Editor → training_goals
// Verify the goal exists and user_id matches your logged-in user

// Check RLS policies are enabled on training_goals table
```

---

### 3. Edit button doesn't work

**Symptoms**: Tapping edit button does nothing or shows error

**Cause**: CreateGoalScreen not handling `goalToEdit` parameter properly

**Solution**: Already fixed in implementation. If still occurring:

1. Check console for errors
2. Verify CreateGoalScreen has `initState` method
3. Hot restart the app (not just hot reload)

---

### 4. Progress doesn't update after adding entry

**Symptoms**:
- Added progress entry but progress bar doesn't change
- Shows "0%" even after adding entries

**Cause**: Provider not refreshing

**Solution**: Pull down to refresh on the goal detail screen, or:

```dart
// This is already implemented in the code:
ref.refresh(goalProgressProvider(goal.id));
ref.refresh(progressEntriesProvider(goal.id));
```

If still not working, check:
1. Progress entries are actually saved (check Supabase Dashboard)
2. User ID matches on the entries
3. Goal type is `custom` (only custom goals use manual progress)

---

### 5. Floating Action Button not showing

**Symptoms**: No "Add Progress" button on custom goals

**Cause**: Goal type is not `custom`

**Solution**: This is correct behavior. Only custom goals show the FAB because:
- **Time goals**: Progress calculated from swim_times table automatically
- **Distance goals**: Progress calculated from training_sets table automatically
- **Frequency goals**: Progress calculated from training_sets table automatically
- **Custom goals**: Require manual progress entry (FAB appears)

To test manual progress:
1. Create a custom goal (Type: Custom)
2. Navigate to its detail screen
3. FAB should appear in bottom-right

---

### 6. "Please enter a valid number" when adding progress

**Symptoms**: Can't add progress entry, validation error

**Cause**: Input is not a valid number

**Solution**:
- Enter numbers only: `5`, `10.5`, `100`
- Don't use commas: `1000` not `1,000`
- Don't use text: `five` won't work, use `5`

---

### 7. Goal deletion doesn't work

**Symptoms**: Error when trying to delete goal

**Possible Causes**:
1. Goal has dependent records (progress entries)
2. RLS policy blocking delete

**Solution**: This should work automatically due to `ON DELETE CASCADE` in the migration. If not:

1. Check console for specific error
2. Verify RLS policies on training_goals table:
```sql
-- Should exist:
CREATE POLICY "Users can delete their own goals"
ON public.training_goals FOR DELETE
USING (auth.uid() = user_id);
```

---

### 8. Status changes (pause/resume/complete) don't work

**Symptoms**: Menu actions don't change goal status

**Cause**: Repository methods not working

**Debug Steps**:
1. Check console for errors
2. Verify training_goals_repository.dart has these methods:
   - `pauseGoal()`
   - `resumeGoal()`
   - `completeGoal()`
3. Check Supabase RLS policies allow UPDATE

**Solution**: Already implemented. If failing, check network connection and Supabase status.

---

### 9. App crashes on hot reload after changes

**Symptoms**: App works initially, crashes after hot reload

**Cause**: Provider state inconsistency

**Solution**:
```bash
# Full restart instead of hot reload
flutter run
# Or press 'R' in terminal (capital R for hot restart)
```

---

### 10. Progress history shows "Error loading history"

**Symptoms**: Can't see past progress entries

**Possible Causes**:
1. Database query error
2. RLS policy blocking SELECT
3. No entries exist yet (should show "No progress entries yet" instead)

**Solution**:
1. Check Supabase logs for the error
2. Verify progress_entries table has correct RLS policies
3. Check goal_id matches in progress_entries table

---

## Verification Commands

### Check if migration was applied:
```sql
-- In Supabase SQL Editor:
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'goal_progress_entries';

-- Should return one row if table exists
```

### Check existing progress entries:
```sql
-- In Supabase SQL Editor:
SELECT * FROM goal_progress_entries
WHERE user_id = auth.uid();
```

### Check goal details:
```sql
-- In Supabase SQL Editor:
SELECT * FROM training_goals
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

---

## Still Having Issues?

If none of these solutions work:

1. **Check Flutter console** for detailed error messages
2. **Check Supabase logs** in Dashboard → Logs
3. **Verify Flutter version**: `flutter --version` (should be 3.0+)
4. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Report the issue** with:
   - Exact error message
   - Steps to reproduce
   - Flutter version
   - Test scenario that failed

---

## Testing Checklist

After fixing issues, verify these work:

- [ ] Navigate to goal detail from goals list
- [ ] Edit goal and save changes
- [ ] Change goal status (pause/resume/complete)
- [ ] Add progress entry to custom goal
- [ ] View progress history
- [ ] Delete progress entry
- [ ] Delete goal
- [ ] Pull to refresh updates data
- [ ] Back navigation works correctly

---

## Next Steps

Once Phase 1 is working perfectly, we can proceed to:
- **Phase 2**: Goal Templates & Milestones
- **Phase 3**: USA Swimming Time Standards
- **Phase 4**: AI Goal Suggestions
- **Phase 5**: Charts & Badges
- **Phase 6**: Notifications
