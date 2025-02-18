// 📄 Calendar component for displaying and selecting workout dates

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var scrollOffset: CGFloat = 0
    
    private let dayWidth: CGFloat = 50 // Width of each day column
    @Namespace private var scrollSpace
    
    // Custom animation for smooth scrolling
    private let smoothScroll = Animation.linear(duration: 0.50)
    
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
                
                Text(viewModel.calendarState.monthYearString())
                    .foregroundColor(.gymtimeText)
                    .font(.headline)
                
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
                    HStack(spacing: 0) {
                        // Add padding at start for centering
                        Spacer()
                            .frame(width: (UIScreen.main.bounds.width - dayWidth) / 2)
                        
                        ForEach(viewModel.calendarState.visibleDates(), id: \.date) { item in
                            VStack(spacing: 8) {
                                Text(item.weekday)
                                    .font(.caption)
                                    .foregroundColor(.gymtimeTextSecondary)
                                
                                Text("\(Calendar.current.component(.day, from: item.date))")
                                    .foregroundColor(textColor(for: item.date))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(backgroundColor(for: item.date))
                                            .overlay(
                                                Circle()
                                                    .stroke(viewModel.calendarState.isDateToday(item.date) ? Color.gymtimeAccent : Color.clear, lineWidth: 2)
                                            )
                                    )
                                    .onTapGesture {
                                        withAnimation(smoothScroll) {
                                            viewModel.selectDate(item.date)
                                            proxy.scrollTo(item.date, anchor: .center)
                                        }
                                    }
                            }
                            .frame(width: dayWidth)
                            .id(item.date)
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
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
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