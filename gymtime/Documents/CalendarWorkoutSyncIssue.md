# Calendar Date Selection and Workout Synchronization Issue

## Overview

This document addresses a potential issue where swiping to a different calendar day in the `WorkoutTableView` might not always update the displayed workouts to match the newly selected date. This is a rare but possible occurrence that could lead to user confusion when the displayed workouts don't match the selected date in the calendar.

## Problem Analysis

After reviewing the codebase, specifically the files:
- `WorkoutTableView.swift`
- `CalendarState.swift`
- `CalendarView.swift`
- `HomeView.swift`
- `HomeViewModel.swift`

The issue appears to be in the `HomeViewModel.swift` file, specifically in the `setupDateChangeObserver()` method:

```swift
private func setupDateChangeObserver() {
    // Observe changes to the selected date
    $calendarState
        .map { $0.selectedDate }
        .removeDuplicates { Calendar.current.isDate($0, inSameDayAs: $1) }
        .dropFirst() // Skip initial value
        .sink { [weak self] _ in
            // Hide suggestions when date changes
            withAnimation {
                self?.isSuggestionsVisible = false
                self?.suggestedWorkouts = []
                self?.blankWorkoutEntry = nil
            }
        }
        .store(in: &cancellables)
}
```

### The Missing Connection

When a user swipes to change the date (using the horizontal swipe handler in `HomeView.swift`):

```swift
.horizontalSwipe(
    onSwipe: { isRight in
        if isRight {
            viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.calendarState.selectedDate) ?? Date())
        } else {
            viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.calendarState.selectedDate) ?? Date())
        }
    },
    isEditing: isEditing,
    isSuggestionsVisible: viewModel.isSuggestionsVisible
)
```

The horizontal swipe calls `selectDate()`, which updates `selectedDate` in the `calendarState`. The issue is that while the observer above reacts to changes in the selected date, it only clears suggestions but doesn't explicitly reload the workouts for the newly selected date.

## Proposed Solution

To fix this issue, we need to explicitly reload workouts whenever the selected date changes.

### Code Change

Update the `setupDateChangeObserver()` method in `HomeViewModel.swift`:

```swift
private func setupDateChangeObserver() {
    // Observe changes to the selected date
    $calendarState
        .map { $0.selectedDate }
        .removeDuplicates { Calendar.current.isDate($0, inSameDayAs: $1) }
        .dropFirst() // Skip initial value
        .sink { [weak self] _ in
            // Hide suggestions when date changes
            withAnimation {
                self?.isSuggestionsVisible = false
                self?.suggestedWorkouts = []
                self?.blankWorkoutEntry = nil
            }
            
            // Add this line to reload workouts for the new date
            self?.loadWorkouts()
        }
        .store(in: &cancellables)
}
```

By adding the call to `loadWorkouts()` after handling suggestions, we ensure that:

1. Each time the selected date changes (whether by swiping or direct tapping in the calendar)
2. The workouts are explicitly reloaded for that specific date

This should create a reliable connection between the calendar date selection and the displayed workouts.

## Implementation Notes

- This assumes that `loadWorkouts()` uses the current `selectedDate` from `calendarState` to fetch the appropriate workouts.
- The fix should be minimal and non-disruptive to the existing codebase.
- This change maintains the existing behavior of clearing suggestions when changing dates.

## Testing Recommendations

After implementing this change, test the following scenarios:

1. Swiping left and right between dates with different workouts
2. Tapping directly on different calendar dates
3. Ensuring workouts always match the selected date
4. Verifying that suggestions are properly cleared when changing dates
5. Testing the edge case of rapidly changing dates in succession

## Conclusion

This simple but effective change should address the issue where workout data might not update correctly when swiping between calendar dates, ensuring a more consistent user experience. 