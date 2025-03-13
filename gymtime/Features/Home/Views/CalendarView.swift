// 📄 Calendar component for displaying and selecting workout dates

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var hasScrolledToToday = false
    @State private var displayedMonth: String = ""
    
    private let dayWidth: CGFloat = 50 // Width of each day column
    @Namespace private var scrollSpace
    
    // Custom animation for smooth scrolling - matched to swipe animation
    private let smoothScroll = Animation.easeInOut(duration: 0.3)
    
    var body: some View {
        VStack(spacing: 16) {
            // Month and Year Navigation
            HStack {
                Button(action: { viewModel.moveToPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gymtimeText)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Text(displayedMonth)
                    .foregroundColor(.gymtimeText)
                    .font(.headline)
                    .animation(.easeInOut, value: displayedMonth)
                
                Spacer()
                
                Button(action: { viewModel.moveToNextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gymtimeText)
                        .imageScale(.large)
                }
            }
            .padding(.horizontal, 24)
            
            // Scrollable Calendar
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    // Day cells
                    HStack(spacing: 0) {
                        // Add padding at start for centering
                        Spacer()
                            .frame(width: (UIScreen.main.bounds.width - dayWidth) / 2)
                        
                        ForEach(viewModel.calendarState.visibleDates(), id: \.date) { item in
                            VStack(spacing: 8) {
                                Text(item.weekday)
                                    .font(.caption)
                                    .foregroundColor(.gymtimeTextSecondary)
                                
                                // Date circle with fire emoji inside
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .fill(backgroundColor(for: item.date))
                                        .overlay(
                                            Circle()
                                                .stroke(viewModel.calendarState.isDateToday(item.date) ? Color.gymtimeAccent : Color.clear, lineWidth: 2)
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    // Date number - centered in circle
                                    Text("\(Calendar.current.component(.day, from: item.date))")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(textColor(for: item.date))
                                        .frame(width: 36, height: 36, alignment: .center)
                                    
                                    // Workout indicator as overlay that doesn't affect layout
                                    if viewModel.calendarState.hasWorkout(for: item.date) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 6))
                                            .foregroundColor(.white)
                                            .offset(y: 12) // Position below the date with 2px spacing
                                            .id("workout-\(item.date)")
                                    }
                                }
                                
                                // Empty space where the emoji used to be
                                Spacer()
                                    .frame(height: 8)
                            }
                            .frame(width: dayWidth)
                            .id(item.date)
                            .onChange(of: item.date) { oldValue, newValue in
                                if viewModel.calendarState.isDateInBufferZone(newValue) {
                                    viewModel.moveToDate(newValue)
                                }
                            }
                            .onTapGesture {
                                withAnimation(smoothScroll) {
                                    // First hide suggestions if visible
                                    if viewModel.isSuggestionsVisible {
                                        viewModel.isSuggestionsVisible = false
                                        viewModel.suggestedWorkouts = []
                                        viewModel.blankWorkoutEntry = nil
                                    }
                                    
                                    // Then select the new date
                                    viewModel.selectDate(item.date)
                                    proxy.scrollTo(item.date, anchor: .center)
                                    updateDisplayedMonth(item.date)
                                }
                            }
                        }
                        
                        // Add padding at end for centering
                        Spacer()
                            .frame(width: (UIScreen.main.bounds.width - dayWidth) / 2)
                    }
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollTargetLayout()
                .scrollClipDisabled()
                .onChange(of: viewModel.calendarState.selectedDate) { _, newDate in
                    withAnimation(smoothScroll) {
                        proxy.scrollTo(newDate, anchor: .center)
                        updateDisplayedMonth(newDate)
                    }
                }
                .onAppear {
                    if !hasScrolledToToday {
                        proxy.scrollTo(viewModel.calendarState.selectedDate, anchor: .center)
                        updateDisplayedMonth(viewModel.calendarState.selectedDate)
                        hasScrolledToToday = true
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color.gymtimeBackground)
    }
    
    private func updateDisplayedMonth(_ date: Date) {
        displayedMonth = viewModel.calendarState.monthYearString(for: date)
    }
    
    private func textColor(for date: Date) -> Color {
        if viewModel.calendarState.isDateSelected(date) {
            return .white
        }
        return .gymtimeText
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if viewModel.calendarState.isDateSelected(date) {
            return .gymtimeAccent
        }
        return .clear
    }
} 