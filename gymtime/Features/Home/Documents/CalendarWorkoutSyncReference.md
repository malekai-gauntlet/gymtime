# Calendar Workout Sync Issue Reference

This is a reference document for a potential issue with calendar date selection not properly synchronizing with displayed workouts.

## Issue Summary

When swiping between calendar days in the WorkoutTableView, the displayed workouts might occasionally not update to match the newly selected date.

## Root Cause

The issue is in `HomeViewModel.swift` where the `setupDateChangeObserver()` method currently only clears suggestions when the date changes, but doesn't explicitly reload workouts.

## Solution Details

The complete documentation, analysis, and proposed solution are available in:

**[/gymtime/Documents/CalendarWorkoutSyncIssue.md](/gymtime/Documents/CalendarWorkoutSyncIssue.md)**

Please refer to the main document for implementation details and testing recommendations. 