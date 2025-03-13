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





- [ ] Add a mini icon to the left of the workout summary text (this would be at the far left if there are no workouts and there's no workout summary) that conveys it can be tapped (otherwise users might not think to tap the workout summary text)