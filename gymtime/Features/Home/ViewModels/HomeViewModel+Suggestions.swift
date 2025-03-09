// 📄 Suggestions management extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Suggestions Management
    
    func toggleSuggestions() {
        withAnimation {
            isSuggestionsVisible.toggle()
            
            if isSuggestionsVisible {
                // Load suggestions
                Task {
                    // Load suggestions
                    suggestedWorkouts = await getWorkoutSuggestions()
                }
            } else {
                // Clear suggestion state when hiding
                suggestedWorkouts = []
            }
        }
    }
    
    func addSuggestionToWorkouts(_ suggestion: WorkoutEntry) {
        print("➕ addSuggestionToWorkouts called for: \(suggestion.exercise) (ID: \(suggestion.id))")
        
        // Create a new entry from the suggestion
        let entry = WorkoutEntry(
            id: UUID(),  // Generate a new ID
            userId: suggestion.userId,
            exercise: suggestion.exercise,
            weight: suggestion.weight,
            sets: suggestion.sets,
            reps: suggestion.reps,
            notes: suggestion.notes,
            date: calendarState.selectedDate  // Already using selected date
        )
        
        print("📝 Created new entry with ID: \(entry.id)")
        
        // Add to workouts
        addWorkout(entry)
        print("✅ Added to workouts array")
        
        // No longer removing the suggestion from the list
        print("ℹ️ Suggestion remains in list for potential reuse")
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
    
    // Get more workout suggestions for the full-screen menu
    func getMoreWorkoutSuggestions() async {
        print("🔄 getMoreWorkoutSuggestions started")
        guard let userId = try? await supabase.auth.session.user.id else { return }
        
        do {
            // Get recent workouts for suggestions
            let response: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(30)  // Fetch more for the full menu
                .execute()
                .value
            
            // Remove duplicates based on exercise name
            var uniqueExercises: Set<String> = []
            let suggestions = response
                .filter { workout in
                    uniqueExercises.insert(workout.exercise).inserted
                }
                .prefix(15)  // Show up to 10 suggestions in the full menu
                .map { $0 }  // Convert ArraySlice back to Array
            
            await MainActor.run {
                withAnimation {
                    suggestedWorkouts = suggestions
                }
            }
            
            // Add before returning suggestions
            print("✅ getMoreWorkoutSuggestions completed, returning \(suggestions.count) suggestions")
        } catch {
            print("Error loading suggestions: \(error)")
        }
    }
    
    // Clear suggestions when the menu is dismissed
    func clearSuggestions() {
        withAnimation {
            suggestedWorkouts = []
            isSuggestionsVisible = false
        }
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