// 📄 Manages data for the exercise history view

import Foundation
import SwiftUI
import Supabase

@MainActor
class ExerciseHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var workouts: [WorkoutEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let supabase: SupabaseClient
    private let exerciseName: String
    
    // MARK: - Init
    init(supabase: SupabaseClient, exerciseName: String) {
        self.supabase = supabase
        self.exerciseName = exerciseName
        Task { await fetchWorkoutHistory() }
    }
    
    // MARK: - Public Methods
    func fetchWorkoutHistory() async {
        isLoading = true
        error = nil
        
        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                error = "Please log in to view history"
                return
            }
            
            // Fetch all workouts for this exercise
            let response: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .eq("exercise", value: exerciseName)
                .order("date", ascending: false)
                .execute()
                .value
            
            workouts = response
            
        } catch {
            self.error = "Failed to load workout history: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
} 