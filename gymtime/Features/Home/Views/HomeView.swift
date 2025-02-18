// 📄 Main home screen view displaying workout summary and quick actions

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedTab: Int = 0  // Add state for selected tab
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
                
                // Workout Table
                WorkoutTableView(workouts: $viewModel.workouts, viewModel: viewModel)
            }
            .background(Color.gymtimeBackground)
            .sheet(isPresented: $showingVoiceLogger) {
                // Temporarily comment out VoiceWorkoutLogger until we create it
                // VoiceWorkoutLogger { workout in
                //     viewModel.addWorkout(workout)
                // }
                Text("Voice Logger Coming Soon")
            }
        }
    }
}

#Preview {
    HomeCoordinator()
}