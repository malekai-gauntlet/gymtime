// 📄 Calendar component for displaying and selecting workout dates

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let weekDays = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]
    private let dragThreshold: CGFloat = 50 // Minimum drag distance to trigger week change
    
    var body: some View {
        VStack(spacing: 16) {
            // Month and Year Navigation
            HStack {
                Button(action: { viewModel.moveToPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gymtimeText)
                }
                
                Spacer()
                
                Text(viewModel.calendarState.monthYearString())
                    .foregroundColor(.gymtimeText)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.moveToNextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gymtimeText)
                }
            }
            .padding(.horizontal)
            
            // Week View with Horizontal Swipe
            HStack(spacing: 0) {
                ForEach(Array(zip(weekDays, viewModel.calendarState.daysInWeek())), id: \.0) { weekDay, date in
                    VStack(spacing: 8) {
                        Text(weekDay)
                            .font(.caption)
                            .foregroundColor(.gymtimeTextSecondary)
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .foregroundColor(textColor(for: date))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(backgroundColor(for: date))
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.calendarState.isDateToday(date) ? Color.gymtimeAccent : Color.clear, lineWidth: 2)
                                    )
                            )
                            .onTapGesture {
                                viewModel.selectDate(date)
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        dragOffset = gesture.translation.width
                    }
                    .onEnded { [viewModel] gesture in
                        isDragging = false
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                        
                        // Determine if we should change weeks
                        if abs(gesture.translation.width) > dragThreshold {
                            if gesture.translation.width > 0 {
                                viewModel.moveToPreviousWeek()
                            } else {
                                viewModel.moveToNextWeek()
                            }
                        }
                    }
            )
            .animation(isDragging ? nil : .easeOut(duration: 0.2), value: dragOffset)
        }
        .padding(.vertical)
        .background(Color.gymtimeBackground)
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