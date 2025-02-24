import SwiftUI

/// FeedView displays a feed of workouts from the user's network
/// Similar to Fitbod's clean, dark interface
struct FeedView: View {
    // MARK: - Properties
    @State private var workouts: [WorkoutFeedEntry] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var likedWorkouts: Set<UUID> = []
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(workouts) { workout in
                        VStack(alignment: .leading, spacing: 0) {
                            // User Info Section
                            HStack(alignment: .center) {
                                // User Avatar
                                Circle()
                                    .fill(Color.gymtimeAccent.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(workout.userName.prefix(1))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gymtimeAccent)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.userName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(workout.location)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                                
                                Spacer()
                                
                                Text(workout.timestamp.formatted(date: .numeric, time: .omitted))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                            .padding(.bottom, 12)
                            
                            // Workout Info Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(workout.workoutType)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(workout.achievement)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineSpacing(4)
                                    }
                                    
                                    Spacer()
                                    
                                    // Like Button
                                    Button(action: {
                                        toggleLike(for: workout.id)
                                    }) {
                                        Image(systemName: likedWorkouts.contains(workout.id) ? "heart.fill" : "heart")
                                            .font(.system(size: 20))
                                            .foregroundColor(likedWorkouts.contains(workout.id) ? .red : .gymtimeTextSecondary)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(white: 0.08))  // Slightly lighter background
            .navigationBarTitle("Feed", displayMode: .inline)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await loadWorkouts()
            }
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
    
    private func toggleLike(for workoutId: UUID) {
        if likedWorkouts.contains(workoutId) {
            likedWorkouts.remove(workoutId)
        } else {
            likedWorkouts.insert(workoutId)
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
