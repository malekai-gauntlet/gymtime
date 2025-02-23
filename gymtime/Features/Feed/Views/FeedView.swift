import SwiftUI

/// FeedView displays a feed of workouts from the user's network
/// Similar to Fitbod's clean, dark interface
struct FeedView: View {
    // MARK: - Properties
    @State private var workouts: [WorkoutFeedEntry] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedTab = "Feed"
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Toggle Tabs
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = "Feed" }) {
                            Text("Feed")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(selectedTab == "Feed" ? .white : Color.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    selectedTab == "Feed" ?
                                    Color(white: 0.22) :
                                    Color.clear
                                )
                        }
                        
                        Button(action: { selectedTab = "Place" }) {
                            Text("Place")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(selectedTab == "Place" ? .white : Color.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    selectedTab == "Place" ?
                                    Color(white: 0.22) :
                                    Color.clear
                                )
                        }
                    }
                    .background(Color(white: 0.17))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black)
                
                // Main Content
                if selectedTab == "Feed" {
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
                } else {
                    // Placeholder for Place tab
                    Color.black
                }
            }
            .navigationBarHidden(true)
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
        
        do {
            // Fetch workouts from Supabase
            let response: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .order("date", ascending: false)
                .limit(10)
                .execute()
                .value
            
            // Map WorkoutEntry to WorkoutFeedEntry
            workouts = response.map { workout in
                WorkoutFeedEntry(
                    id: workout.id,
                    userName: "User \(workout.userId.uuidString.prefix(4))", // Temporary user display
                    workoutType: workout.exercise,
                    location: "Gym", // Default location for now
                    achievement: formatAchievement(workout),
                    timestamp: workout.date
                )
            }
        } catch {
            showingError = true
            errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }
    }
    
    // Helper function to format the achievement string
    private func formatAchievement(_ workout: WorkoutEntry) -> String {
        var parts: [String] = []
        
        if let weight = workout.weight {
            parts.append("\(Int(weight))lbs")
        }
        
        if let sets = workout.sets, let reps = workout.reps {
            parts.append("\(sets)×\(reps)")
        }
        
        if let notes = workout.notes {
            parts.append(notes)
        }
        
        return parts.isEmpty ? "Completed workout" : parts.joined(separator: " • ")
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