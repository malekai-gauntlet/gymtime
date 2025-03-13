# Display Real Usernames in Feed View: Implementation Checklist

## Overview
This checklist outlines the steps required to update the Feed feature to display real usernames instead of placeholder user IDs. Currently, the app shows generic identifiers like "User 501d" rather than the actual display names from user profiles.

## Database Schema Context
- [x] `workouts` table: contains workout data with `user_id` foreign key
- [x] `profiles` table: contains user display information (`username`, `full_name`)
- [x] Relationship: `workouts.user_id` → `profiles.id`
- [x] `workout_profiles` view: combines workout data with user profile information

## Implementation Checklist

### 1. Update Supabase Query
- [x] Modify `loadWorkouts()` function in `FeedView.swift`
- [x] Update Supabase query to use the workout_profiles view instead of workouts table
- [x] Ensure query includes all necessary profile fields (username, full_name)

### 2. Create/Update Data Models
- [x] Create a new `WorkoutProfileEntry` struct for handling data from workout_profiles view
- [x] Add username and fullName fields to the model
- [x] Ensure proper Codable conformance for JSON decoding
- [x] Handle potential null values in profile data

### 3. Update Mapping Logic
- [x] Modify the mapping from Supabase response to `WorkoutFeedEntry`
- [x] Extract username or full_name from profile data
- [x] Implement fallback logic if profile data is missing (use fullName if username is empty)

### 4. Update UI Components (if needed)
- [x] No changes needed - FeedEntryView already correctly displays the username

### 5. Testing
- [ ] Test with various user profiles (with/without username/full_name)
- [ ] Verify correct display of usernames in feed

### 6. Follow-up Tasks
- [ ] Consider adding user avatars from profile data
- [ ] Add ability to tap on username to view user profile
- [ ] Consider caching profile data for improved performance

## Notes
- This implementation leverages the existing `workout_profiles` view in Supabase
- The view dynamically reflects changes from both workouts and profiles tables
- If the workout_profiles view doesn't exist, it may need to be created in Supabase 