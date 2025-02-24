// 📄 Suggestions management extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Suggestions Management
    
    func toggleSuggestions() {
        withAnimation {
            isSuggestionsVisible.toggle()
            
            if isSuggestionsVisible {
                // Create blank entry for new workout
                Task {
                    guard let userId = try? await supabase.auth.session.user.id else { return }
                    await MainActor.run {
                        blankWorkoutEntry = WorkoutEntry(
                            userId: userId,
                            exercise: "",
                            date: calendarState.selectedDate
                        )
                        
                        // Load suggestions
                        Task {
                            suggestedWorkouts = await getWorkoutSuggestions()
                        }
                    }
                }
            } else {
                // Clear suggestion state
                blankWorkoutEntry = nil
                suggestedWorkouts = []
            }
        }
    }
    
    func addSuggestionToWorkouts(_ suggestion: WorkoutEntry) {
        guard var entry = blankWorkoutEntry else { return }
        
        // Update blank entry with suggestion details
        entry.exercise = suggestion.exercise
        entry.weight = suggestion.weight
        entry.sets = suggestion.sets
        entry.reps = suggestion.reps
        entry.notes = suggestion.notes
        
        // Add to workouts
        addWorkout(entry)
        
        // Reset suggestion state
        withAnimation {
            isSuggestionsVisible = false
            blankWorkoutEntry = nil
            suggestedWorkouts = []
        }
    }
    
    func updateBlankWorkoutField(field: String, value: String) {
        guard var entry = blankWorkoutEntry else { return }
        
        // Update the specified field
        switch field {
        case "exercise":
            entry.exercise = value
        case "weight":
            entry.weight = Double(value)
        case "sets":
            entry.sets = Int(value)
        case "reps":
            entry.reps = Int(value)
        case "notes":
            entry.notes = value
        default:
            return
        }
        
        blankWorkoutEntry = entry
    }
    
    private func getWorkoutSuggestions() async -> [WorkoutEntry] {
        guard let userId = try? await supabase.auth.session.user.id else { return [] }
        
        do {
            // Get recent workouts for suggestions
            let response: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(10)  // Still fetch 10 for more variety
                .execute()
                .value
            
            // Remove duplicates based on exercise name and limit to 3 suggestions
            var uniqueExercises: Set<String> = []
            return response
                .filter { workout in
                    uniqueExercises.insert(workout.exercise).inserted
                }
                .prefix(3)  // Limit to 3 suggestions
                .map { $0 }  // Convert ArraySlice back to Array
            
        } catch {
            print("Error loading suggestions: \(error)")
            return []
        }
    }
} 