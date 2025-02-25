// 📄 Main home screen view displaying workout summary and quick actions

import SwiftUI

// Horizontal swipe handler
struct HorizontalSwipeHandler: ViewModifier {
    let onSwipe: (Bool) -> Void // true for right, false for left
    let isEditing: Bool
    let isSuggestionsVisible: Bool
    
    // Minimum distance to trigger a horizontal swipe
    private let horizontalThreshold: CGFloat = 50
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture()
                    .onEnded { gesture in
                        // Only process horizontal swipes if not editing and suggestions aren't visible
                        if !isEditing && !isSuggestionsVisible {
                            let horizontalMovement = abs(gesture.translation.width)
                            let verticalMovement = abs(gesture.translation.height)
                            
                            // Only trigger if primarily horizontal (with bias toward vertical)
                            if horizontalMovement > verticalMovement * 1.2 && 
                               horizontalMovement > horizontalThreshold {
                                print("👉 Horizontal swipe detected: \(gesture.translation.width > 0 ? "RIGHT" : "LEFT")")
                                onSwipe(gesture.translation.width > 0)
                            }
                        }
                    }
            )
    }
}

extension View {
    func horizontalSwipe(onSwipe: @escaping (Bool) -> Void, isEditing: Bool, isSuggestionsVisible: Bool) -> some View {
        self.modifier(HorizontalSwipeHandler(onSwipe: onSwipe, isEditing: isEditing, isSuggestionsVisible: isSuggestionsVisible))
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
                
                // Workout Table with horizontal swipe handling
                WorkoutTableView(workouts: $viewModel.workouts, viewModel: viewModel, isEditing: $isEditing)
                    .horizontalSwipe(
                        onSwipe: { isRight in
                            // Don't animate the scroll, just select the new date
                            // The selection will trigger the color change animations
                            if isRight {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.calendarState.selectedDate) ?? Date())
                            } else {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.calendarState.selectedDate) ?? Date())
                            }
                        },
                        isEditing: isEditing,
                        isSuggestionsVisible: viewModel.isSuggestionsVisible
                    )
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