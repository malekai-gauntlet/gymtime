// 📄 Manages calendar state and date calculations for workout tracking

import Foundation

struct CalendarState {
    // Current date being viewed
    private(set) var selectedDate: Date
    private(set) var displayedWeek: Date
    private let calendar = Calendar.current
    
    // Dates with logged workouts
    private(set) var datesWithWorkouts: Set<Date> = []
    
    // Constants for date range
    private let bufferWeeks = 2 // Number of weeks to buffer on each side
    private let visibleWeeks = 5 // Number of weeks to show at once
    
    // Initialize with current date
    init(initialDate: Date = Date()) {
        // Start with the current date
        let now = Date()
        
        // Ensure we're working with the start of the day
        if let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) {
            self.selectedDate = startOfDay
            self.displayedWeek = startOfDay
        } else {
            self.selectedDate = now
            self.displayedWeek = now
        }
    }
    
    // MARK: - Date Management
    
    mutating func selectDate(_ date: Date) {
        // Ensure we're working with the start of the day
        if let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) {
            selectedDate = startOfDay
            displayedWeek = startOfDay
        } else {
            selectedDate = date
            displayedWeek = date
        }
    }
    
    mutating func moveToDate(_ date: Date) {
        // Ensure we're working with the start of the day
        if let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) {
            displayedWeek = startOfDay
        } else {
            displayedWeek = date
        }
    }
    
    // MARK: - Navigation
    
    mutating func moveToNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedWeek) {
            moveToDate(newDate)
        }
    }
    
    mutating func moveToPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedWeek) {
            moveToDate(newDate)
        }
    }
    
    // MARK: - Workout Date Management
    
    mutating func updateWorkoutDates(_ dates: Set<Date>) {
        // Convert all dates to start of day to ensure consistent comparisons
        self.datesWithWorkouts = Set(dates.map { calendar.startOfDay(for: $0) })
    }
    
    func hasWorkout(for date: Date) -> Bool {
        // Ensure we compare with start of day
        let normalizedDate = calendar.startOfDay(for: date)
        return datesWithWorkouts.contains { calendar.isDate($0, inSameDayAs: normalizedDate) }
    }
    
    // MARK: - Calendar Helpers
    
    func dateForOffset(_ offset: CGFloat, dayWidth: CGFloat) -> Date {
        let dayOffset = Int(round(offset / dayWidth))
        return calendar.date(byAdding: .day, value: -dayOffset, to: displayedWeek) ?? displayedWeek
    }
    
    func visibleDates() -> [(weekday: String, date: Date)] {
        // Calculate total days to show (buffer weeks + visible weeks + buffer weeks)
        let totalDays = (bufferWeeks * 2 + visibleWeeks) * 7
        
        // Get the start date (going back buffer weeks from displayed week)
        guard let startDate = calendar.date(byAdding: .day, value: -(totalDays/2), to: displayedWeek) else {
            return []
        }
        
        // Create array of dates with their weekday labels
        var dates: [(weekday: String, date: Date)] = []
        var currentDate = startDate
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EE"
        
        // Add dates for the total range
        for _ in 0..<totalDays {
            let weekday = weekdayFormatter.string(from: currentDate).uppercased()
            dates.append((weekday: weekday, date: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    // Get the month and year for a specific date
    func monthYearString(for date: Date? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date ?? displayedWeek)
    }
    
    func isDateSelected(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: selectedDate, toGranularity: .day)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    // Helper to determine if a date is within the buffer zone
    func isDateInBufferZone(_ date: Date) -> Bool {
        let daysFromDisplayed = calendar.dateComponents([.day], from: displayedWeek, to: date).day ?? 0
        let bufferDays = bufferWeeks * 7
        return abs(daysFromDisplayed) > bufferDays
    }
} 