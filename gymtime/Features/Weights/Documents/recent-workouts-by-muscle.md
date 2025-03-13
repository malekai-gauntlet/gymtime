# Recent Workouts by Muscle Group Feature

## Overview
Display recent workouts organized by muscle group in the Weights tab, allowing users to quickly view their exercise history and progress for each muscle group.

## UI Components

### 1. Muscle Group Toggle Row
- Horizontal scrollable row at the top
- Each muscle group as a selectable button/pill
- Visual indication of selected group
- Muscle groups: Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Cardio
- Default to first non-empty muscle group

### 2. Workout Cards Section
- Scrollable list below muscle group toggles
- Each card displays:
  - Exercise name
  - Sets and reps
  - Weight used
  - Date of workout
- Cards sorted by date (most recent first)
- Empty state handling when no workouts exist

## Data Flow

### 1. ViewModel Updates
- Add state for:
  - Selected muscle group
  - Dictionary of workouts by muscle group
  - Loading state
  - Error state
- Add functions for:
  - Fetching workouts for selected muscle group
  - Selecting muscle group
  - Caching fetched data

### 2. Supabase Query
- Query workouts table filtered by:
  - Current user
  - Selected muscle group
  - Recent timeframe (e.g., last 30 days)
- Order by date descending
- Include all relevant fields:
  - exercise
  - sets
  - reps
  - weight
  - date
  - notes (optional)

### 3. Data Management
- Cache fetched workouts to minimize database calls
- Implement refresh mechanism
- Handle errors gracefully
- Update cache when new workouts are logged

## Implementation Steps

1. **Update WeightsViewModel**
   - Add necessary state properties
   - Implement data fetching logic
   - Add muscle group selection handling
   - Implement caching mechanism

2. **Create UI Components**
   - Build MuscleGroupToggleRow component
   - Build WorkoutCard component
   - Create empty state view
   - Implement loading state UI

3. **Update WeightsView**
   - Integrate toggle row
   - Add workout cards section
   - Handle loading and error states
   - Add pull-to-refresh functionality

4. **Add Navigation/Interaction**
   - Handle muscle group selection
   - Implement smooth transitions between groups
   - Add any necessary animations

5. **Testing & Optimization**
   - Test with various data scenarios
   - Optimize query performance
   - Ensure smooth UI transitions
   - Test error handling

## Future Enhancements
- Add progress tracking over time
- Implement personal record highlighting
- Add detailed view for each exercise
- Include weight progression graphs
- Add exercise suggestions based on history

## Notes
- Keep UI clean and focused
- Ensure fast loading times
- Cache data appropriately
- Handle edge cases (no data, errors, etc.)
- Consider offline support
- Maintain consistent design with rest of app 