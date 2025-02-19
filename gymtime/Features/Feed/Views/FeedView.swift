import SwiftUI

/// FeedView displays a feed of workouts from the user's network
/// Similar to Fitbod's clean, dark interface
struct FeedView: View {
    // MARK: - Properties
    @State private var workouts: [WorkoutFeedEntry] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                ForEach(workouts) { workout in
                    VStack(spacing: 0) {
                        FeedEntryView(workout: workout)
                        
                        if workout.id != workouts.last?.id {
                            Divider()
                                .background(Color.gymtimeTextSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await loadWorkouts()
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.automatic)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadWorkouts()
        }
    }
    
    // MARK: - Methods
    private func loadWorkouts() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual workout loading logic
        // This is just sample data for now
        workouts = [
            WorkoutFeedEntry(id: UUID(), 
                           userName: "Robert Price",
                           workoutType: "Morning Run",
                           location: "Deschutes National Forest, Oregon",
                           achievement: "27.99 mi • 15,158 ft elevation",
                           timestamp: Date()),
            WorkoutFeedEntry(id: UUID(),
                           userName: "Sarah Chen",
                           workoutType: "Strength Training",
                           location: "LifeTime Sky NYC",
                           achievement: "Bench Press: 225lbs × 5 • Deadlift: 315lbs × 3",
                           timestamp: Date().addingTimeInterval(-3600)),
            WorkoutFeedEntry(id: UUID(),
                           userName: "Mike Johnson",
                           workoutType: "Evening HIIT",
                           location: "Home Gym",
                           achievement: "45 min • 650 cal burned",
                           timestamp: Date().addingTimeInterval(-7200))
        ]
    }
}

// MARK: - Preview
#Preview {
    FeedView()
}

// MARK: - Supporting Types
/// Model representing a single workout entry in the feed
struct WorkoutFeedEntry: Identifiable {
    let id: UUID
    let userName: String
    let workoutType: String
    let location: String
    let achievement: String
    let timestamp: Date
} 