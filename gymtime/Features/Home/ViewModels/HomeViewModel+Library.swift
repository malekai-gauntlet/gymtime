// 📄 Library management extensions for HomeViewModel

import Foundation
import SwiftUI
import Supabase

extension HomeViewModel {
    // MARK: - Exercise Library Management
    
    /// Loads all exercises from the library
    func loadExerciseLibrary() async {
        print("🔄 Loading exercise library...")
        isLoadingLibrary = true
        
        do {
            let response: [Exercise] = try await supabase
                .from("exercises")
                .select()
                .order("name", ascending: true)  // Default to alphabetical sort
                .execute()
                .value
            
            await MainActor.run {
                withAnimation {
                    libraryExercises = response
                }
                isLoadingLibrary = false
            }
            
            print("✅ Loaded \(response.count) exercises from library")
        } catch {
            print("❌ Error loading exercise library: \(error)")
            await MainActor.run {
                self.error = "Failed to load exercise library"
                isLoadingLibrary = false
            }
        }
    }
    
    /// Add an exercise from the library to the current workout
    func addLibraryExerciseToWorkouts(_ exercise: Exercise) {
        print("➕ Adding library exercise to workouts: \(exercise.name) (ID: \(exercise.id))")
        
        Task {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                print("❌ No user ID found when adding library exercise")
                self.error = "Please log in to add workouts"
                return
            }
            
            // Convert Exercise to WorkoutEntry
            let entry = exercise.toWorkoutEntry(userId: userId, date: calendarState.selectedDate)
            
            // Add to workouts
            addWorkout(entry)
            print("✅ Added library exercise to workouts")
        }
    }
    
    /// Performs fuzzy matching between a search query and a target string
    /// - Parameters:
    ///   - searchText: The user's search query
    ///   - targetString: The string to match against (e.g., exercise name)
    /// - Returns: Boolean indicating if the strings fuzzy-match
    func fuzzyMatch(searchText: String, targetString: String) -> Bool {
        // If search text is empty, it matches everything
        if searchText.isEmpty { return true }
        
        // Quick case-insensitive direct check first (for exact/substring matches)
        if targetString.localizedCaseInsensitiveContains(searchText) {
            print("📍 Direct match: '\(searchText)' in '\(targetString)'")
            return true
        }
        
        // Prepare strings for comparison
        let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let target = targetString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split search into words/tokens
        let searchWords = search.split(separator: " ")
        
        // Track overall matching status
        var allWordsMatched = true
        
        // Process each word in the search
        for word in searchWords {
            // Skip empty words
            if word.isEmpty { continue }
            
            // Try sequence matching first
            var sequenceFound = false
            var searchIndex = word.startIndex
            var targetIndex = target.startIndex
            
            // Check if all characters exist in sequence (with gaps allowed)
            while searchIndex < word.endIndex && targetIndex < target.endIndex {
                if word[searchIndex] == target[targetIndex] {
                    searchIndex = word.index(after: searchIndex)
                    if searchIndex == word.endIndex {
                        sequenceFound = true
                        print("📍 Sequence match found for '\(word)' in '\(target)'")
                        break
                    }
                }
                targetIndex = target.index(after: targetIndex)
            }
            
            // If sequence matching failed, try character percentage matching
            if !sequenceFound {
                // Count matching characters
                let targetChars = Set(target)
                let wordChars = Set(word)
                let matchingChars = targetChars.intersection(wordChars)
                let matchPercentage = Double(matchingChars.count) / Double(word.count)
                
                // Threshold: 90% of characters must match (increased from 60%)
                if matchPercentage >= 0.9 {
                    print("📍 Character match: '\(word)' in '\(target)' - \(Int(matchPercentage * 100))%")
                } else {
                    print("❌ No match for '\(word)' in '\(target)' - \(Int(matchPercentage * 100))%")
                    allWordsMatched = false
                    break
                }
            }
        }
        
        // Print result of matching
        if allWordsMatched {
            print("✅ Fuzzy match: '\(searchText)' matches '\(targetString)'")
        }
        
        return allWordsMatched
    }
    
    /// Filters the exercise library by search text using fuzzy matching
    func filterLibraryExercises(searchText: String) -> [Exercise] {
        if searchText.isEmpty {
            return libraryExercises
        } else {
            return libraryExercises.filter { exercise in
                // Check for matches in name, category, or muscle group
                return fuzzyMatch(searchText: searchText, targetString: exercise.name) ||
                       fuzzyMatch(searchText: searchText, targetString: exercise.category) ||
                       fuzzyMatch(searchText: searchText, targetString: exercise.muscleGroup)
            }
        }
    }
    
    /// Sort the exercise library by different criteria
    func sortLibraryExercises(by sortMethod: LibrarySortMethod) {
        withAnimation {
            switch sortMethod {
            case .alphabetical:
                libraryExercises.sort { $0.name < $1.name }
            case .muscleGroup:
                libraryExercises.sort { $0.muscleGroup == $1.muscleGroup ? $0.name < $1.name : $0.muscleGroup < $1.muscleGroup }
            }
        }
    }
}

// MARK: - Sort Method Enum

enum LibrarySortMethod {
    case alphabetical
    case muscleGroup
} 