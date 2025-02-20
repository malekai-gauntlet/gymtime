// 📄 Model for storing workout analysis results and injury prevention insights

import Foundation

/// Represents a muscle group's training frequency and status
struct MuscleGroupStatus: Codable, Equatable {
    /// Number of times this muscle group has been trained
    let trainingCount: Int
    /// Date of the last workout targeting this muscle group
    let lastWorkoutDate: Date?
    /// Calculated strength score (0-100)
    let strengthScore: Double
    
    init(trainingCount: Int = 0, lastWorkoutDate: Date? = nil, strengthScore: Double = 0) {
        self.trainingCount = trainingCount
        self.lastWorkoutDate = lastWorkoutDate
        self.strengthScore = strengthScore
    }
}

/// Main model for workout analysis results
struct WorkoutAnalysis: Codable, Equatable {
    /// Status for each muscle group
    var muscleGroups: [String: MuscleGroupStatus]
    
    /// Ratio between pull and push exercises (1.0 is balanced)
    var pushPullRatio: Double
    
    /// Array of warning messages for potential issues
    var warnings: [String]
    
    /// Array of recommended actions
    var recommendations: [String]
    
    /// Date when this analysis was performed
    let analysisDate: Date
    
    /// Number of days of history analyzed
    let daysAnalyzed: Int
    
    init(
        muscleGroups: [String: MuscleGroupStatus] = [:],
        pushPullRatio: Double = 0.0,
        warnings: [String] = [],
        recommendations: [String] = [],
        daysAnalyzed: Int = 30,
        analysisDate: Date = Date()
    ) {
        self.muscleGroups = muscleGroups
        self.pushPullRatio = pushPullRatio
        self.warnings = warnings
        self.recommendations = recommendations
        self.daysAnalyzed = daysAnalyzed
        self.analysisDate = analysisDate
    }
}

// MARK: - Helper Extensions

extension WorkoutAnalysis {
    /// Checks if there are any warnings that need attention
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
    
    /// Checks if there are any recommendations available
    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }
    
    /// Returns true if the push/pull ratio is within acceptable range (0.8 - 1.2)
    var isPushPullBalanced: Bool {
        (0.8...1.2).contains(pushPullRatio)
    }
    
    /// Gets the status for a specific muscle group
    func status(for muscleGroup: String) -> MuscleGroupStatus {
        muscleGroups[muscleGroup] ?? MuscleGroupStatus()
    }
    
    /// Checks if a muscle group needs attention (hasn't been trained in 7 days)
    func needsAttention(_ muscleGroup: String) -> Bool {
        guard let lastWorkout = muscleGroups[muscleGroup]?.lastWorkoutDate else {
            return true
        }
        return Date().timeIntervalSince(lastWorkout) > (7 * 24 * 60 * 60) // 7 days in seconds
    }
}

// MARK: - Constants

extension WorkoutAnalysis {
    /// Known muscle groups for categorization
    static let knownMuscleGroups = [
        "chest",
        "back",
        "shoulders",
        "biceps",
        "triceps",
        "legs",
        "core"
    ]
    
    /// Mapping of exercises to their primary muscle groups
    static let exerciseToMuscleGroups: [String: [String]] = [
        // Push exercises
        "Bench Press": ["chest", "shoulders", "triceps"],
        "Shoulder Press": ["shoulders", "triceps"],
        "Push-ups": ["chest", "shoulders", "triceps"],
        
        // Pull exercises
        "Pull-ups": ["back", "biceps"],
        "Lat Pulldown": ["back", "biceps"],
        "Cable Rows": ["back", "biceps"],
        "Barbell Rows": ["back", "biceps"],
        "Face Pulls": ["shoulders", "back"],
        
        // Leg exercises
        "Squats": ["legs"],
        "Deadlift": ["legs", "back"],
        
        // Core exercises
        "Chin-ups": ["back", "biceps", "core"]
    ]
} 