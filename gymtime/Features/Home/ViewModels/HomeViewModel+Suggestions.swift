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
                // Clear suggestion state when hiding
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
        
        // Remove the added suggestion from the suggestions list
        withAnimation {
            if let index = suggestedWorkouts.firstIndex(where: { $0.id == suggestion.id }) {
                suggestedWorkouts.remove(at: index)
            }
        }
        
        // Create a new blank workout entry and fetch new suggestions
        Task {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            
            // Get new suggestions to replace the one we just added
            let newSuggestions = await getWorkoutSuggestions()
            
            await MainActor.run {
                withAnimation {
                    // Create new blank entry
                    blankWorkoutEntry = WorkoutEntry(
                        userId: userId,
                        exercise: "",
                        date: calendarState.selectedDate
                    )
                    
                    // Update suggestions, but avoid duplicates
                    let existingExercises = Set(suggestedWorkouts.map { $0.exercise })
                    let filteredNewSuggestions = newSuggestions.filter { !existingExercises.contains($0.exercise) }
                    
                    // Add one new suggestion if available
                    if let newSuggestion = filteredNewSuggestions.first {
                        suggestedWorkouts.append(newSuggestion)
                    }
                }
            }
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