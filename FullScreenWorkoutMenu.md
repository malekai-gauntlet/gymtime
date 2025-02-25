# Full-Screen Workout Menu Implementation Checklist

## Overview
This checklist outlines the steps needed to implement a full-screen menu that appears when tapping the plus icon in the Gymtime app. The menu will be similar to the iOS contact creation screen and will display workout suggestions similar to MyFitnessPal.

## Implementation Checklist

### 1. Create New View Files
- [x] Create `WorkoutMenuView.swift` for the full-screen menu
- [x] Create `WorkoutSuggestionRow.swift` for individual workout suggestion items (or include in main file)

### 2. Update ViewModel
- [x] Add `getMoreWorkoutSuggestions()` function to `HomeViewModel+Suggestions.swift`
- [x] Ensure proper data loading for the full-screen menu

### 3. Update WorkoutTableView
- [x] Add state variable for showing the menu: `@State private var showingWorkoutMenu = false`
- [x] Modify the plus button to show the full-screen menu instead of toggling suggestions
- [x] Add sheet presentation for the menu

### 4. Design the Menu UI
- [x] Implement navigation bar with "Cancel" and "Done" buttons
- [x] Create search bar for filtering workouts
- [x] Add tab selector for different workout categories
- [x] Design quick action buttons (Voice Log, Scan Barcode)
- [x] Create history/suggestions section with workout list
- [x] Style everything according to app design guidelines

### 5. Connect Menu Functionality
- [x] Connect search functionality to filter suggestions
- [x] Implement tab switching logic
- [x] Connect "Voice Log" button to recording functionality
- [x] Make suggestion rows tappable to add workouts
- [x] Ensure "Done" button adds any pending workout and dismisses the menu

### 6. Polish and Optimize
- [ ] Add smooth transitions and animations
- [x] Optimize performance for large suggestion lists
- [x] Ensure proper keyboard handling
- [ ] Test on different device sizes
- [x] Remove voice log and scan a barcode cards
- [x] Remove "All" "My Workouts" "My recipes" "my foods" toggle

## Testing Checklist
- [x] Verify menu appears correctly when tapping plus button
- [x] Test that suggestions load properly
- [x] Confirm adding a workout from suggestions works
- [x] Test search functionality filters correctly
- [x] Verify voice recording integration works from the menu
- [x] Ensure menu dismisses properly with both Cancel and Done buttons
- [ ] Test on both light and dark mode

## Future Enhancements (Post-MVP)
- [ ] Add workout categories and filtering
- [ ] Implement barcode scanning for supplements/food
- [ ] Add custom workout creation form
- [ ] Implement search history and favorites
- [ ] Add animations for a more polished experience