# Minimal Feed MVP Checklist

## 1. Update FeedView's loadWorkouts()
- [ ] Use existing Supabase client to fetch all workouts
- [ ] Order by date descending
- [ ] Limit to most recent 10-20 workouts initially
- [ ] Map WorkoutEntry to WorkoutFeedEntry format

## 2. Update WorkoutFeedEntry Display
- [ ] Modify FeedEntryView to show:
  - Exercise name as workoutType
  - Sets/reps/weight as achievement
  - User's name (from userId)
  - Simple timestamp

That's it! No need to:
- Create new services
- Modify existing models
- Add complex pagination yet
- Add complex achievement formatting yet