# Past Workout Logging Implementation Plan

This document outlines the steps required to implement the ability to log workouts for past dates, not just the current day.

## Overview

Currently, all workouts are logged with the current date. We need to modify the app to allow users to log workouts for any selected date in the calendar.

## Implementation Checklist

### 1. Update HomeViewModel

- [x] HomeViewModel already has a `calendarState` property that tracks the selected date
- [ ] Modify workout creation to use the selected date instead of the current date
- [ ] Ensure the `toggleRecording` method passes the selected date to the workout creation process
- [ ] Add a visual indicator showing which date workouts are being recorded for

### 2. Update WorkoutParser

- [ ] Modify the `parse` method to accept a date parameter
- [ ] Pass this date to the WorkoutEntry constructor instead of using the default (current) date

### 3. Update Audio Recording Flow

- [ ] Ensure that when recording finishes, the selected date is passed to the parser
- [ ] Update the UI to indicate which date workouts are being recorded for during voice recording

### 4. Update Manual Entry Flow

- [ ] When manually adding workouts (through the plus button menu), use the selected date
- [ ] Add the selected date to the blank workout entry creation

### 5. Update UI

- [ ] Add a clear visual indicator of which date is currently active for logging
- [ ] Consider adding a confirmation when logging workouts for past dates
- [ ] Ensure the calendar selection is intuitive and obvious

### 6. Testing

- [ ] Test recording workouts for past dates
- [ ] Test manual entry for past dates
- [ ] Verify workouts appear on the correct date in the calendar
- [ ] Test edge cases (midnight crossover, different timezones)

## Code Changes Required

### HomeViewModel.swift

1. Update `processRecordedSpeech` method to use selected date
2. Update manual workout addition methods to use selected date
3. Ensure any Supabase queries filter by the proper date

### WorkoutParser.swift

1. Update `parse` method signature to accept a date parameter
2. Pass this date to WorkoutEntry constructor

### UI Components

1. Update recording UI to show active date
2. Update workout entry UI to indicate the target date
3. Consider adding date selection to manual entry flow

## Considerations

- Timezone handling: Ensure dates are correctly interpreted in the user's timezone
- Date validation: Consider if you want to allow future dates or limit to past dates only
- User feedback: Make it obvious which date workouts are being logged for 