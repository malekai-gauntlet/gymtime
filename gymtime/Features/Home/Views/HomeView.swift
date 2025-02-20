// 📄 Main home screen view displaying workout summary and quick actions

import SwiftUI

// SwipeArea view to handle horizontal swipes
struct SwipeArea: View {
    let onSwipe: (Bool) -> Void // true for right, false for left
    @GestureState private var translation: CGFloat = 0
    private let swipeThreshold: CGFloat = 50
    
    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.1)) // Temporary to see the area
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { gesture in
                        if abs(gesture.translation.width) > swipeThreshold {
                            onSwipe(gesture.translation.width > 0)
                        }
                    }
            )
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedTab: Int = 0
    @State private var showingVoiceLogger = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Section
                CalendarView(viewModel: viewModel)
                
                // Workout Tracking Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Workouts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gymtimeText)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical)
                .background(Color.gymtimeBackground)
                
                // Workout Table with SwipeArea
                ZStack {
                    WorkoutTableView(workouts: $viewModel.workouts, viewModel: viewModel)
                        .allowsHitTesting(true) // Ensure workout interactions still work
                    
                    // SwipeArea fills available space
                    GeometryReader { geometry in
                        SwipeArea { isRight in
                            if isRight {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.calendarState.selectedDate) ?? Date())
                            } else {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.calendarState.selectedDate) ?? Date())
                            }
                        }
                        .frame(height: viewModel.workouts.isEmpty ? 200 : 100) // Adjust height based on workouts
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 140) // Stay above buttons
                        .allowsHitTesting(true)
                        .zIndex(1) // Between table and buttons
                    }
                }
            }
            .background(Color.gymtimeBackground)
            .sheet(isPresented: $showingVoiceLogger) {
                Text("Voice Logger Coming Soon")
            }
        }
    }
}

#Preview {
    HomeCoordinator()
}