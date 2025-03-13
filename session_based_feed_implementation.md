# Session-Based Workout Feed Implementation Checklist

## Overview
Convert the current single-exercise feed entries to session-based entries where multiple workouts by the same user on the same day appear as a single entry in the feed.

## Data Modeling

- [ ] Create a new `WorkoutSessionEntry` model with:
  - [ ] Session ID (UUID)
  - [ ] User information (name, avatar)
  - [ ] Date of session
  - [ ] Location
  - [ ] Summary stats (total exercises, duration if available)
  - [ ] Array of individual exercises/workouts
  - [ ] Showcases most impressive / most challenging workout the user did in the session
  - [ ] Props count for the entire session
  - [ ] Tracking for whether the current user has propped this session

- [ ] Create an `ExerciseEntry` model for individual exercises within a session:
  - [ ] Exercise ID
  - [ ] Exercise name
  - [ ] Weight, sets, reps
  - [ ] Other exercise-specific data

## Database Changes

- [ ] Create a new Supabase view or function that groups workouts by user and date
  - [ ] Group by user_id and date
  - [ ] Aggregate exercise data
  - [ ] Ensure props are counted correctly for the session

- [ ] Test the new view/function to ensure it returns expected data:
  - [ ] Proper grouping of exercises
  - [ ] All exercise details preserved
  - [ ] Accurate props counting

## Fetch Logic Updates

- [ ] Modify `loadWorkouts()` method to:
  - [ ] Query the new session-based view/function
  - [ ] Transform results into `WorkoutSessionEntry` objects
  - [ ] Handle props for sessions instead of individual exercises

- [ ] Update props toggling logic to work with sessions:
  - [ ] Update `toggleProps()` method for session-based props
  - [ ] Ensure UI updates correctly when props are added/removed

## UI Component Changes

- [ ] Create a new `SessionFeedEntryView` component:
  - [ ] Display user info and session date
  - [ ] Show summary of the workout (e.g., "5 exercises • 45 minutes")
  - [ ] Display props and actions

- [ ] Design expandable/collapsible exercise list:
  - [ ] Collapsed view showing first 1-2 exercises
  - [ ] Expand/collapse functionality
  - [ ] Individual exercise rows showing details

- [ ] Update `FeedView` to use new session-based components:
  - [ ] Replace `WorkoutFeedEntry` items with `WorkoutSessionEntry`
  - [ ] Update ForEach loop to render new components
  - [ ] Adjust spacing and layout for the new design

## Testing & Refinement

- [ ] Test with various workout scenarios:
  - [ ] Single exercise sessions
  - [ ] Multi-exercise sessions
  - [ ] Sessions with different achievement types
  - [ ] Sessions with and without props

- [ ] Implement feedback from user testing:
  - [ ] Adjust UI based on feedback
  - [ ] Fix any bugs or edge cases

- [ ] Performance testing:
  - [ ] Ensure feed loads quickly
  - [ ] Test with large datasets
  - [ ] Optimize if necessary

## Activity View Updates

- [ ] Update `ActivityView` to work with session-based props:
  - [ ] Modify activity data model
  - [ ] Update activity fetching logic
  - [ ] Update activity display components

## Final Polishing

- [ ] Add animations for expanding/collapsing sessions
- [ ] Ensure accessibility support for the new components
- [ ] Add any final UI refinements (colors, spacing, etc.)
- [ ] Update preview code for SwiftUI previews 