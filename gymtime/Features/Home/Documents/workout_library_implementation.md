# Workout Library Implementation Plan

## Overview
Add a comprehensive library of exercises below the Suggestions section in the WorkoutMenuView. This allows users to find and log workouts they haven't done before without using voice input - perfect for crowded gym environments.

## Implementation Checklist

### Supabase Setup
- [x] Create a new "exercises" table in Supabase with fields:
  - [x] id (UUID, primary key)
  - [x] name (String, unique)
  - [x] category (String, e.g., "Strength", "Cardio", "Stretching")
  - [x] muscle_group (String, e.g., "Chest", "Back", "Legs")
  - [x] equipment (String, nullable)
  - [x] description (Text, nullable)
  - [x] created_at (Timestamp)
- [x] Populate the table with a standard list of common exercises
- [x] Set up appropriate RLS (Row Level Security) policies
- [x] Create an API endpoint or function to fetch exercises

### Model Updates
- [x] Add Exercise model struct (if not already existing)
- [x] Update HomeViewModel to include methods for fetching library exercises
- [x] Add state management for library exercise list
- [ ] Implement caching for library data to improve performance

### UI Implementation
- [x] Update WorkoutMenuView to include Library section below Suggestions
- [x] Add section header with "Library" title and sorting options
- [x] Create scrollable list view for library exercises, sorted alphabetically
- [x] Implement UI for library exercise rows (similar to suggestions)
- [x] Update search functionality to filter both suggestions and library items
- [x] Add visual indicators to differentiate between suggestions and library items

### Functionality
- [x] Implement fetch logic to load library exercises on view appear
- [x] Add sorting functionality (alphabetical by default)
- [x] Ensure search works across both suggestions and library sections
- [x] Implement "add to workout" functionality for library items (matching suggestion behavior)
- [x] Add loading indicators and empty state views
- [ ] Optimize performance for large exercise libraries

### Testing & Refinement
- [ ] Test search functionality works across both sections
- [ ] Verify sorting functions properly
- [ ] Ensure adding workouts from library works identically to suggestions
- [ ] Check performance with large number of exercises
- [ ] Test library section scrolling behavior
- [ ] Verify accessibility features work correctly

### Final Polish
- [ ] Add animations for smooth transitions
- [ ] Implement error handling and retry mechanisms
- [ ] Add analytics tracking for library usage
- [ ] Document the feature for future reference
- [ ] Consider adding category filtering in future iteration 