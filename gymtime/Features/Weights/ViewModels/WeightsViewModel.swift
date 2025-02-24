// 📄 Manages the business logic and data for the weights feature

import Foundation
import SwiftUI
import Supabase

class WeightsViewModel: ObservableObject {
    // MARK: - Constants
    static let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Core", "Cardio"]
    
    // MARK: - Published Properties
    @Published var selectedMuscleGroup: String = muscleGroups[0]  // Default to first group
    @Published var workouts: [WorkoutEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let supabase: SupabaseClient
    
    // MARK: - Init
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        // Load initial data
        Task { await fetchWorkouts() }
    }
    
    // MARK: - Public Methods
    @MainActor
    func fetchWorkouts() async {
        isLoading = true
        error = nil
        
        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                error = "Please log in to view workouts"
                return
            }
            
            // Fetch workouts for selected muscle group
            let response: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .eq("muscle_group", value: selectedMuscleGroup)
                .order("date", ascending: false)
                .limit(10)  // Start with last 10 workouts for performance
                .execute()
                .value
            
            workouts = response
            
        } catch {
            self.error = "Failed to load workouts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectMuscleGroup(_ group: String) {
        guard WeightsViewModel.muscleGroups.contains(group) else { return }
        selectedMuscleGroup = group
        Task { await fetchWorkouts() }
    }
} 