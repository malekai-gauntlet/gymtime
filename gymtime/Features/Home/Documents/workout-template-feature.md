# Quick Workout Template Feature Implementation

## Overview
Allow users to quickly load previous workouts as templates by tapping the workout summary area and selecting from recent workout days.

## MVP Implementation Steps

### 1. UI Layer ✅
- [x] Add a menu icon (three horizontal lines in accent color) next to the workout summary text
- [x] Make workout summary area tappable in `HomeView`
- [x] Create a menu that appears on tap showing:
  - Summary text & date (e.g., "Push Day • Sun 3/9")
  - Visual separation between menu items
- [x] Add visual feedback for tap interaction (haptic feedback)

### 2. Data Layer ✅
- [x] Create a function in `HomeViewModel` to fetch recent unique workout summaries
  - Query `daily_workout_summaries` table
  - Include both summary and date in the response
  - Group by summary to avoid duplicates
  - Limit to 4 most recent
  - Sort by date descending
- [x] Fix timezone handling to display correct dates (UTC to local conversion)

### 3. Template Loading (Next Step)
- [ ] Create function to fetch all workouts for a selected date
- [ ] Add function to copy workouts from template to current day
  - Copy exercise name, weights, sets, reps
  - Update creation date to current date
  - Generate new UUIDs for each workout

### 4. Error Handling
- [ ] Add error states for failed template loading
- [ ] Show loading state while template is being applied
- [ ] Add error message if no previous workouts are found

## Future Enhancements (Post-MVP)
- Save custom templates
- Edit templates before applying
- Preview template contents before applying
- Favorite specific workout days
- Show exercise count in menu (e.g., "Push Day (6 exercises)")

## Technical Notes
- Use existing Supabase tables and models
- Leverage current workout data structure
- Keep UI changes minimal for MVP
- Handle dates in UTC format when displaying to avoid timezone shifts 