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
                VStack(spacing: 16) {
                    // Month and Year
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.gymtimeText)
                        }
                        
                        Spacer()
                        
                        Text("February")
                            .foregroundColor(.gymtimeText)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gymtimeText)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Week View
                    HStack(spacing: 0) {
                        ForEach(["SU", "MO", "TU", "WE", "TH", "FR", "SA"], id: \.self) { day in
                            VStack(spacing: 8) {
                                Text(day)
                                    .font(.caption)
                                    .foregroundColor(.gymtimeTextSecondary)
                                
                                Text("17")
                                    .foregroundColor(.gymtimeText)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .stroke(Color.gymtimeAccent, lineWidth: day == "MO" ? 2 : 0)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color.gymtimeBackground)
                
                // Workout Tracking Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Workouts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gymtimeText)
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gymtimeTextSecondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
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