# ⚠️ Calendar Sync Issue Note

## Issue
There's a potential issue in `HomeViewModel.swift` where calendar date selection might not properly sync with displayed workouts.

## Location
The issue is in the `setupDateChangeObserver()` method which needs to be updated to explicitly call `loadWorkouts()` when the date changes.

## Current Implementation
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

## Proposed Fix
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

For full documentation, see:
- [/gymtime/Documents/CalendarWorkoutSyncIssue.md](/gymtime/Documents/CalendarWorkoutSyncIssue.md) 