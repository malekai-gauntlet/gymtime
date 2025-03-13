// 📄 Service for analyzing workout data and detecting potential muscle imbalances

import Foundation

/// Service responsible for analyzing workout data and generating injury prevention insights
class MuscleBalanceAnalyzer {
    
    // MARK: - Types
    
    /// Represents a workout entry from the database
    struct WorkoutEntry {
        let exercise: String
        let weight: Double
        let sets: Int
        let reps: Int
        let date: Date
    }
    
    /// Error types that can occur during analysis
    enum AnalysisError: Error {
        case insufficientData
        case invalidExercise(String)
        case calculationError
    }
    
    // MARK: - Properties
    
    /// Number of days to analyze for trends
    private let analysisTimeframe: Int
    
    // MARK: - Initialization
    
    init(analysisTimeframe: Int = 30) {
        self.analysisTimeframe = analysisTimeframe
    }
    
    // MARK: - Public Methods
    
    /// Analyzes workout history to generate insights and recommendations
    /// - Parameter workouts: Array of workout entries to analyze
    /// - Returns: WorkoutAnalysis containing insights and recommendations
    func analyzeWorkouts(_ workouts: [WorkoutEntry]) throws -> WorkoutAnalysis {
        guard !workouts.isEmpty else {
            throw AnalysisError.insufficientData
        }
        
        // Initialize analysis components
        var muscleGroups: [String: MuscleGroupStatus] = [:]
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Calculate muscle group frequencies and last workout dates
        let groupFrequencies = calculateMuscleGroupFrequencies(from: workouts)
        
        // Calculate push/pull ratio
        let pushPullRatio = calculatePushPullRatio(from: workouts)
        
        // Generate muscle group statuses
        for group in WorkoutAnalysis.knownMuscleGroups {
            let status = generateMuscleGroupStatus(
                for: group,
                frequencies: groupFrequencies,
                workouts: workouts
            )
            muscleGroups[group] = status
        }
        
        // Generate warnings and recommendations
        (warnings, recommendations) = generateInsights(
            muscleGroups: muscleGroups,
            pushPullRatio: pushPullRatio,
            workouts: workouts
        )
        
        // Create and return analysis
        return WorkoutAnalysis(
            muscleGroups: muscleGroups,
            pushPullRatio: pushPullRatio,
            warnings: warnings,
            recommendations: recommendations,
            daysAnalyzed: analysisTimeframe
        )
    }
    
    // MARK: - Private Methods
    
    /// Calculates how often each muscle group is trained
    private func calculateMuscleGroupFrequencies(from workouts: [WorkoutEntry]) -> [String: (count: Int, lastDate: Date?)] {
        var frequencies: [String: (count: Int, lastDate: Date?)] = [:]
        
        for workout in workouts {
            guard let muscleGroups = WorkoutAnalysis.exerciseToMuscleGroups[workout.exercise] else {
                continue
            }
            
            for group in muscleGroups {
                let current = frequencies[group] ?? (count: 0, lastDate: nil)
                let newCount = current.count + 1
                let newDate = max(workout.date, current.lastDate ?? workout.date)
                frequencies[group] = (count: newCount, lastDate: newDate)
            }
        }
        
        return frequencies
    }
    
    /// Calculates the ratio between push and pull exercises
    private func calculatePushPullRatio(from workouts: [WorkoutEntry]) -> Double {
        var pushCount = 0
        var pullCount = 0
        
        for workout in workouts {
            guard let muscleGroups = WorkoutAnalysis.exerciseToMuscleGroups[workout.exercise] else {
                continue
            }
            
            // Classify as push or pull based on primary muscle groups
            if muscleGroups.contains("chest") || 
               (muscleGroups.contains("shoulders") && !muscleGroups.contains("back")) ||
               (muscleGroups.contains("triceps") && !muscleGroups.contains("back")) {
                pushCount += 1
            }
            
            if muscleGroups.contains("back") || muscleGroups.contains("biceps") {
                pullCount += 1
            }
        }
        
        // Avoid division by zero
        return pullCount > 0 ? Double(pushCount) / Double(pullCount) : 0
    }
    
    /// Generates status for a specific muscle group
    private func generateMuscleGroupStatus(
        for group: String,
        frequencies: [String: (count: Int, lastDate: Date?)],
        workouts: [WorkoutEntry]
    ) -> MuscleGroupStatus {
        let frequency = frequencies[group] ?? (count: 0, lastDate: nil)
        
        // Calculate strength score (0-100) based on:
        // - Training frequency
        // - Volume (sets * reps * weight)
        // - Consistency
        let strengthScore = calculateStrengthScore(
            group: group,
            frequency: frequency.count,
            workouts: workouts
        )
        
        return MuscleGroupStatus(
            trainingCount: frequency.count,
            lastWorkoutDate: frequency.lastDate,
            strengthScore: strengthScore
        )
    }
    
    /// Calculates a strength score for a muscle group
    private func calculateStrengthScore(
        group: String,
        frequency: Int,
        workouts: [WorkoutEntry]
    ) -> Double {
        // Base score from frequency (0-40 points)
        let frequencyScore = min(Double(frequency) * 10, 40)
        
        // Volume score (0-40 points)
        var volumeScore: Double = 0
        var maxVolume: Double = 0
        
        for workout in workouts {
            guard let muscleGroups = WorkoutAnalysis.exerciseToMuscleGroups[workout.exercise],
                  muscleGroups.contains(group) else {
                continue
            }
            
            let volume = workout.weight * Double(workout.sets * workout.reps)
            maxVolume = max(maxVolume, volume)
            volumeScore += volume
        }
        
        // Normalize volume score
        volumeScore = min((volumeScore / Double(analysisTimeframe)) / 1000, 40)
        
        // Consistency score (0-20 points)
        let consistencyScore = calculateConsistencyScore(for: group, workouts: workouts)
        
        return min(frequencyScore + volumeScore + consistencyScore, 100)
    }
    
    /// Calculates a consistency score based on workout spacing
    private func calculateConsistencyScore(
        for group: String,
        workouts: [WorkoutEntry]
    ) -> Double {
        var dates: [Date] = []
        
        // Collect workout dates for this muscle group
        for workout in workouts {
            guard let muscleGroups = WorkoutAnalysis.exerciseToMuscleGroups[workout.exercise],
                  muscleGroups.contains(group) else {
                continue
            }
            dates.append(workout.date)
        }
        
        guard dates.count > 1 else { return 0 }
        
        // Sort dates and calculate average gap between workouts
        dates.sort()
        var totalGap: TimeInterval = 0
        for i in 1..<dates.count {
            totalGap += dates[i].timeIntervalSince(dates[i-1])
        }
        
        let averageGap = totalGap / Double(dates.count - 1)
        let daysGap = averageGap / (24 * 60 * 60) // Convert to days
        
        // Score based on optimal gap (around 3-4 days)
        let score = 20 * (1 - min(abs(3.5 - daysGap) / 7, 1))
        return score
    }
    
    /// Generates warnings and recommendations based on analysis
    private func generateInsights(
        muscleGroups: [String: MuscleGroupStatus],
        pushPullRatio: Double,
        workouts: [WorkoutEntry]
    ) -> (warnings: [String], recommendations: [String]) {
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Check push/pull balance
        if pushPullRatio > 1.5 {
            warnings.append("Your training favors push exercises significantly over pull exercises")
            recommendations.append("Include more pulling movements (rows, pull-ups) in your routine")
        } else if pushPullRatio < 0.67 {
            warnings.append("Your training favors pull exercises significantly over push exercises")
            recommendations.append("Include more pushing movements (bench press, shoulder press) in your routine")
        }
        
        // Check for neglected muscle groups
        for group in WorkoutAnalysis.knownMuscleGroups {
            guard let status = muscleGroups[group] else { continue }
            
            if status.trainingCount == 0 {
                warnings.append("\(group.capitalized) appears to be completely neglected")
                recommendations.append("Add \(group) exercises to your routine")
            } else if let lastWorkout = status.lastWorkoutDate,
                      Date().timeIntervalSince(lastWorkout) > (7 * 24 * 60 * 60) {
                warnings.append("\(group.capitalized) hasn't been trained in over a week")
                recommendations.append("Schedule a \(group) workout soon")
            }
        }
        
        // Check for overtraining
        for group in WorkoutAnalysis.knownMuscleGroups {
            guard let status = muscleGroups[group] else { continue }
            
            if status.trainingCount > analysisTimeframe / 2 {
                warnings.append("Potential overtraining of \(group)")
                recommendations.append("Consider reducing \(group) training frequency")
            }
        }
        
        return (warnings, recommendations)
    }
} 