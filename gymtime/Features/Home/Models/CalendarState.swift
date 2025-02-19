// 📄 Manages calendar state and date calculations for workout tracking

import Foundation

struct CalendarState {
    // Current date being viewed
    private(set) var selectedDate: Date
    private(set) var displayedWeek: Date
    private let calendar = Calendar.current
    
    // Initialize with current date
    init(initialDate: Date = Date()) {
        // Start with the current date
        let now = Date()
        
        // Ensure we're working with the start of the day
        if let startOfDay = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) {
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
        if let startOfDay = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) {
            selectedDate = startOfDay
            displayedWeek = startOfDay
        } else {
            selectedDate = date
            displayedWeek = date
        }
    }
    
    mutating func moveToDate(_ date: Date) {
        // Ensure we're working with the start of the day
        if let startOfDay = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) {
            displayedWeek = startOfDay
        } else {
            displayedWeek = date
        }
    }
    
    // Week Navigation
    mutating func moveToNextWeek() {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeek) {
            moveToDate(newDate)
        }
    }
    
    mutating func moveToPreviousWeek() {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeek) {
            moveToDate(newDate)
        }
    }
    
    // Month Navigation
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
    
    // MARK: - Calendar Helpers
    
    func dateForOffset(_ offset: CGFloat, dayWidth: CGFloat) -> Date {
        let dayOffset = Int(round(offset / dayWidth))
        return calendar.date(byAdding: .day, value: -dayOffset, to: displayedWeek) ?? displayedWeek
    }
    
    func visibleDates(totalDays: Int = 21) -> [(weekday: String, date: Date)] {
        // Get the start date (going back 10 days from displayed week)
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
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedWeek)
    }
    
    func isDateSelected(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: selectedDate, toGranularity: .day)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
} 