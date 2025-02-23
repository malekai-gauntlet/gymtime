// 📄 Calendar management extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Calendar Navigation
    
    func moveToNextMonth() {
        calendarState.moveToNextMonth()
        loadWorkouts()
    }
    
    func moveToPreviousMonth() {
        calendarState.moveToPreviousMonth()
        loadWorkouts()
    }
    
    func selectDate(_ date: Date) {
        print("📅 Selecting date: \(date)")
        
        // Reset UI states
        isSuggestionsVisible = false
        blankWorkoutEntry = nil
        
        calendarState.selectDate(date)
        loadWorkouts()
    }
    
    func moveToDate(_ date: Date) {
        calendarState.moveToDate(date)
        loadWorkouts()
    }
    
    // MARK: - Calendar Management
    
    func dateForOffset(_ offset: CGFloat, dayWidth: CGFloat) -> Date {
        calendarState.dateForOffset(offset, dayWidth: dayWidth)
    }
    
    func isDateSelected(_ date: Date) -> Bool {
        calendarState.isDateSelected(date)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        calendarState.isDateToday(date)
    }
    
    func monthYearString(for date: Date? = nil) -> String {
        calendarState.monthYearString(for: date)
    }
    
    func visibleDates() -> [(weekday: String, date: Date)] {
        calendarState.visibleDates()
    }
    
    // MARK: - Swipe Gesture Logging
    
    func logSwipeGestureStart() {
        print("👆 Swipe gesture started")
    }
    
    func logSwipeGestureEnd(direction: String, succeeded: Bool) {
        print("👆 Swipe gesture ended")
        print("   Direction: \(direction)")
        print("   Successfully changed date: \(succeeded)")
    }
} 