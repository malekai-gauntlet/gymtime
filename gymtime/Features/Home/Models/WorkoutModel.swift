// Models/WorkoutModel.swift
@MainActor
class WorkoutModel: ObservableObject {
    static let shared = WorkoutModel()
    
    @Published private(set) var workouts: [WorkoutEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // Start with just one core function
    func loadWorkouts(for date: Date) async {
        do {
            isLoading = true
            error = nil
            
            guard let userId = try? await supabase.auth.session.user.id else {
                error = "Please log in to view workouts"
                return
            }
            
            let response: [WorkoutEntry] = try await supabase.database
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
                
            workouts = response.filter { workout in
                Calendar.current.isDate(workout.date, equalTo: date, toGranularity: .day)
            }
        } catch {
            self.error = "Failed to load workouts: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // Move one function at a time
    func addWorkout(_ workout: WorkoutEntry) async {
        do {
            try await supabase.database
                .from("workouts")
                .insert(workout)
                .execute()
            
            workouts.append(workout)
        } catch {
            error = "Failed to save workout: \(error.localizedDescription)"
        }
    }
}