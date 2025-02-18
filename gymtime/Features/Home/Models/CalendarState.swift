// 📄 Manages calendar state and date calculations for workout tracking

import Foundation

struct CalendarState {
    // Current date being viewed
    private(set) var selectedDate: Date
    private(set) var displayedWeek: Date
    
    // Initialize with current date
    init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        self.displayedWeek = initialDate
    }
    
    // MARK: - Date Management
    
    mutating func selectDate(_ date: Date) {
        selectedDate = date
        displayedWeek = date // Move displayed week when selecting a date
    }
    
    mutating func moveToNextWeek() {
        displayedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: displayedWeek) ?? displayedWeek
    }
    
    mutating func moveToPreviousWeek() {
        displayedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: displayedWeek) ?? displayedWeek
    }
    
    mutating func moveToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: displayedWeek) {
            // Keep the same week position in the new month
            let weekOfMonth = Calendar.current.component(.weekOfMonth, from: displayedWeek)
            let newDateWeekOfMonth = Calendar.current.component(.weekOfMonth, from: newDate)
            
            // Adjust to maintain similar week position
            let weekDiff = weekOfMonth - newDateWeekOfMonth
            displayedWeek = Calendar.current.date(byAdding: .weekOfMonth, value: weekDiff, to: newDate) ?? newDate
        }
    }
    
    mutating func moveToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: displayedWeek) {
            // Keep the same week position in the new month
            let weekOfMonth = Calendar.current.component(.weekOfMonth, from: displayedWeek)
            let newDateWeekOfMonth = Calendar.current.component(.weekOfMonth, from: newDate)
            
            // Adjust to maintain similar week position
            let weekDiff = weekOfMonth - newDateWeekOfMonth
            displayedWeek = Calendar.current.date(byAdding: .weekOfMonth, value: weekDiff, to: newDate) ?? newDate
        }
    }
    
    // MARK: - Calendar Helpers
    
    func daysInWeek() -> [Date] {
        let calendar = Calendar.current
        
        // Get start of the week containing the displayed date
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: displayedWeek) else {
            return []
        }
        
        // Create array of dates for the week
        var dates: [Date] = []
        var date = weekInterval.start
        
        // Add each day of the week
        while date < weekInterval.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedWeek)
    }
    
    func isDateSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .day)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
} 