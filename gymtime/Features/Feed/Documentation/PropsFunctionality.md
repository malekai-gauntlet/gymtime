# Props Functionality Checklist (MVP)

This document outlines the minimum viable steps to implement the "Props" feature (similar to likes/kudos) in GymTime.

## Database Setup
- [x] Create `workout_props` table in Supabase

## Core Functionality
- [x] Update `toggleLike()` function to save props to Supabase
  - Insert record when a user gives props
  - Delete record when a user removes props

## Feed View Updates
- [x] Modify `loadWorkouts()` to include props count for each workout
- [x] Update UI to show actual props count instead of just local state

## Activity View (Basic Version)
- [ ] Create function to fetch user's activity from `workout_props` table
- [ ] Show real props data in the Activity View
- [ ] Set the notification counter based on unread props

## Testing
- [ ] Test giving and removing props
- [ ] Verify props persist after app restart
- [ ] Confirm activity feed shows accurate props information

---

### Future Enhancements (Post-MVP)
* Real-time updates when props are given
* Analytics for most popular workouts
* Enhanced activity feed with more interaction types
* Automatic props suggestions 