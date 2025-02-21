// 📄 Main home screen view displaying workout summary and quick actions

import SwiftUI

// SwipeArea view to handle horizontal swipes
struct SwipeArea: View {
    let onSwipe: (Bool) -> Void // true for right, false for left
    @GestureState private var translation: CGFloat = 0
    private let swipeThreshold: CGFloat = 50
    let isEditing: Bool  // Add isEditing parameter
    
    var body: some View {
        Rectangle()
            .fill(.clear) // No visible tint
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        if !isEditing {  // Only update translation if not editing
                            state = value.translation.width
                        }
                    }
                    .onEnded { gesture in
                        if !isEditing && abs(gesture.translation.width) > swipeThreshold {
                            onSwipe(gesture.translation.width > 0)
                        }
                    }
            )
            .allowsHitTesting(!isEditing)  // Disable hit testing when editing
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedTab: Int = 0
    @State private var showingVoiceLogger = false
    @State private var isEditing = false  // Add editing state
    
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
                        
                        if !viewModel.aiWorkoutSummary.isEmpty {
                            Text(viewModel.aiWorkoutSummary
                                .trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
                                + " Day"
                            )
                                .font(.subheadline)
                                .foregroundColor(.gymtimeTextSecondary)
                                .animation(.easeInOut, value: viewModel.aiWorkoutSummary)
                        } else if viewModel.isLoadingSummary {
                            HStack(spacing: 4) {
                                Text("Summarizing")
                                    .font(.subheadline)
                                    .foregroundColor(.gymtimeTextSecondary)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical)
                .background(Color.gymtimeBackground)
                
                // Workout Table with SwipeArea
                ZStack {
                    WorkoutTableView(workouts: $viewModel.workouts, viewModel: viewModel, isEditing: $isEditing)
                        .allowsHitTesting(true)
                    
                    // SwipeArea fills available space
                    GeometryReader { geometry in
                        SwipeArea(onSwipe: { isRight in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isRight {
                                    viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.calendarState.selectedDate) ?? Date())
                                } else {
                                    viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.calendarState.selectedDate) ?? Date())
                                }
                            }
                        }, isEditing: isEditing)
                        .frame(height: viewModel.workouts.isEmpty ? 300 : 150)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 140)
                        .allowsHitTesting(!viewModel.isSuggestionsVisible && !isEditing)
                        .opacity(viewModel.isSuggestionsVisible ? 0 : 1)
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