// 📄 Manages workout progression data and statistics

import Foundation
import SwiftUI
import Combine
import Supabase

/// Represents weekly exercise progression data
struct WeeklyProgression: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let exercises: [ExerciseProgress]
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}

/// Represents progression data for a single exercise
struct ExerciseProgress: Identifiable {
    let id = UUID()
    let exerciseName: String
    let maxWeight: Double?
    let bestSet: (weight: Double, reps: Int, sets: Int?)?
    
    // Calculate if this is an improvement over the previous data
    var isImprovement: Bool = false
    var improvementPercentage: Double = 0.0
}

@MainActor
class ProgressionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weeklyProgressions: [WeeklyProgression] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasAttemptedFetch = false
    
    // Number of weeks to look back
    private let weekLookback = 6
    
    // MARK: - Initialization
    init() {
        // No automatic loading on init
    }
    
    // MARK: - Public Methods
    /// Fetches workout progression data for the past several weeks
    func fetchWorkoutProgression() async {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                error = "Please log in to view progression"
                isLoading = false
                return
            }
            
            // Calculate date range (current week and past weeks)
            let calendar = Calendar.current
            let now = Date()
            let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            
            var weeklyData: [WeeklyProgression] = []
            
            // Fetch data for each week, starting with the current week
            for weekOffset in 0..<weekLookback {
                // Calculate start and end dates for this week
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart)!
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
                
                // Fetch workouts for this week
                let workouts: [WorkoutEntry] = try await supabase
                    .from("workouts")
                    .select()
                    .eq("user_id", value: userId)
                    .gte("date", value: formatDate(weekStart))
                    .lte("date", value: formatDate(weekEnd))
                    .execute()
                    .value
                
                // Process workout data
                let exerciseProgress = processExercises(workouts)
                
                // Add this week's data
                let weekProgression = WeeklyProgression(
                    weekStartDate: weekStart,
                    weekEndDate: weekEnd,
                    exercises: exerciseProgress
                )
                
                weeklyData.append(weekProgression)
            }
            
            // Calculate improvements by comparing weeks
            weeklyData = calculateImprovements(weeklyData)
            
            // Only update weeklyProgressions if we actually found data
            if !weeklyData.isEmpty && weeklyData.first?.exercises.isEmpty == false {
                weeklyProgressions = weeklyData
            }
            
            hasAttemptedFetch = true
            
        } catch {
            self.error = "Failed to load progression data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helper Methods
    
    /// Process workout entries to get exercise progression data
    private func processExercises(_ workouts: [WorkoutEntry]) -> [ExerciseProgress] {
        // Group workouts by exercise
        let exerciseGroups = Dictionary(grouping: workouts) { $0.exercise }
        
        // Process each exercise group
        return exerciseGroups.map { exerciseName, entries -> ExerciseProgress in
            // Find max weight for this exercise
            let maxWeight = entries.compactMap { $0.weight }.max()
            
            // Find best set (weight × reps)
            let bestSet = entries.compactMap { entry -> (weight: Double, reps: Int, sets: Int?, value: Double)? in
                guard let weight = entry.weight, let reps = entry.reps else { return nil }
                return (weight: weight, reps: reps, sets: entry.sets, value: weight * Double(reps))
            }.max { $0.value < $1.value }
            
            return ExerciseProgress(
                exerciseName: exerciseName,
                maxWeight: maxWeight,
                bestSet: bestSet.map { (weight: $0.weight, reps: $0.reps, sets: $0.sets) }
            )
        }.sorted { $0.exerciseName < $1.exerciseName }
    }
    
    /// Calculate improvements by comparing progression between weeks
    private func calculateImprovements(_ weeklyData: [WeeklyProgression]) -> [WeeklyProgression] {
        guard weeklyData.count >= 2 else { return weeklyData }
        
        var result = weeklyData
        
        // Start from most recent week (index 0) and compare with previous week
        for i in 0..<(weeklyData.count - 1) {
            let currentWeek = weeklyData[i]
            let previousWeek = weeklyData[i + 1]
            
            // Create a map of previous week's exercises for quick lookup
            let previousExercises = Dictionary(uniqueKeysWithValues: 
                previousWeek.exercises.map { ($0.exerciseName, $0) }
            )
            
            // Update exercises in current week to reflect improvements
            let updatedExercises = currentWeek.exercises.map { exercise -> ExerciseProgress in
                guard let previousExercise = previousExercises[exercise.exerciseName] else {
                    // No previous data to compare
                    return exercise
                }
                
                // Calculate weight improvement
                var isImprovement = false
                var improvementPercentage = 0.0
                
                // Check max weight improvement
                if let currentMax = exercise.maxWeight, 
                   let previousMax = previousExercise.maxWeight, 
                   currentMax > previousMax {
                    isImprovement = true
                    improvementPercentage = (currentMax - previousMax) / previousMax * 100
                }
                
                // Update exercise with improvement data
                var updatedExercise = exercise
                updatedExercise.isImprovement = isImprovement
                updatedExercise.improvementPercentage = improvementPercentage
                
                return updatedExercise
            }
            
            // Update result with improved exercises
            result[i] = WeeklyProgression(
                weekStartDate: currentWeek.weekStartDate,
                weekEndDate: currentWeek.weekEndDate,
                exercises: updatedExercises
            )
        }
        
        return result
    }
    
    /// Format date for Supabase query
    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
} 