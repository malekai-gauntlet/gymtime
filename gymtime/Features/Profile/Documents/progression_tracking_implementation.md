# Progression Tracking Feature Implementation

## Overview
This document outlines the implementation steps for adding a workout progression tracking feature to the Profile section of the GymTime app. This feature will allow users to view their strength gains over time for various exercises, similar to the example provided.

## Requirements
- Track progression by week
- Show weight and sets/reps for each exercise
- Display in a table format with exercises as rows and weeks as columns
- Integrate into the Profile section
- Highlight improvements with color coding

## Implementation Steps

### 1. Create Data Models

#### 1.1 ProgressionViewModel (gymtime/Features/Profile/ViewModels/ProgressionViewModel.swift)

```swift
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
    let bestSet: (weight: Double, reps: Int)?
    let totalVolume: Double
    
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
    
    // Number of weeks to look back
    private let weekLookback = 6
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        Task {
            await fetchWorkoutProgression()
        }
    }
    
    // MARK: - Public Methods
    /// Fetches workout progression data for the past several weeks
    func fetchWorkoutProgression() async {
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
            
            weeklyProgressions = weeklyData
            
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
            let bestSet = entries.compactMap { entry -> (weight: Double, reps: Int, value: Double)? in
                guard let weight = entry.weight, let reps = entry.reps else { return nil }
                return (weight: weight, reps: reps, value: weight * Double(reps))
            }.max { $0.value < $1.value }
            
            // Calculate total volume (sum of weight × sets × reps)
            let totalVolume = entries.reduce(0.0) { total, entry in
                guard let weight = entry.weight, let sets = entry.sets, let reps = entry.reps else { return total }
                return total + (weight * Double(sets) * Double(reps))
            }
            
            return ExerciseProgress(
                exerciseName: exerciseName,
                maxWeight: maxWeight,
                bestSet: bestSet.map { (weight: $0.weight, reps: $0.reps) },
                totalVolume: totalVolume
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
```

### 2. Create UI Components

#### 2.1 ProgressionView (gymtime/Features/Profile/Views/ProgressionView.swift)

```swift
// 📄 Displays the user's workout progression over time

import SwiftUI

struct ProgressionView: View {
    @StateObject private var viewModel = ProgressionViewModel()
    
    // Column width constraints
    private let exerciseColumnWidth: CGFloat = 120
    private let dataColumnWidth: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Strength Progression")
                .font(.title2.bold())
                .foregroundColor(.gymtimeText)
                .padding(.top)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.gymtimeText)
                    .scaleEffect(1.5)
                    .padding()
                Text("Loading progression data...")
                    .foregroundColor(.gymtimeTextSecondary)
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .padding()
                Text(error)
                    .foregroundColor(.gymtimeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Try Again") {
                    Task {
                        await viewModel.fetchWorkoutProgression()
                    }
                }
                .padding()
                .background(Color.gymtimeAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
                Spacer()
            } else if viewModel.weeklyProgressions.isEmpty {
                Spacer()
                Image(systemName: "dumbbell")
                    .font(.system(size: 50))
                    .foregroundColor(.gymtimeTextSecondary)
                    .padding()
                Text("No workout data found. Start logging your workouts to track progression!")
                    .foregroundColor(.gymtimeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                // Scrollable table
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        // Table header row
                        HStack(spacing: 0) {
                            // Exercise column header
                            Text("Exercise")
                                .font(.caption.bold())
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(width: exerciseColumnWidth, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.3))
                            
                            // Week column headers
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(viewModel.weeklyProgressions) { week in
                                        Text(week.weekLabel)
                                            .font(.caption.bold())
                                            .foregroundColor(.gymtimeTextSecondary)
                                            .frame(width: dataColumnWidth)
                                            .padding(.vertical, 12)
                                            .background(Color.black.opacity(0.3))
                                    }
                                }
                            }
                        }
                        
                        // Get unique exercises from all weeks
                        let allExercises = getUniqueExercises()
                        
                        // Table data rows
                        ForEach(allExercises, id: \.self) { exerciseName in
                            ExerciseProgressionRow(
                                exerciseName: exerciseName,
                                weeklyProgressions: viewModel.weeklyProgressions,
                                exerciseColumnWidth: exerciseColumnWidth,
                                dataColumnWidth: dataColumnWidth
                            )
                        }
                    }
                }
            }
        }
        .background(Color.gymtimeBackground)
        .navigationBarTitle("Progression", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            Task {
                await viewModel.fetchWorkoutProgression()
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.gymtimeAccent)
        })
    }
    
    // Helper to get unique exercises across all weeks
    private func getUniqueExercises() -> [String] {
        var exercises = Set<String>()
        
        for week in viewModel.weeklyProgressions {
            for exercise in week.exercises {
                exercises.insert(exercise.exerciseName)
            }
        }
        
        return exercises.sorted()
    }
}

// MARK: - Supporting Views

struct ExerciseProgressionRow: View {
    let exerciseName: String
    let weeklyProgressions: [WeeklyProgression]
    let exerciseColumnWidth: CGFloat
    let dataColumnWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            // Exercise name
            Text(exerciseName)
                .font(.subheadline)
                .foregroundColor(.gymtimeText)
                .frame(width: exerciseColumnWidth, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.15))
            
            // Weekly data
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(weeklyProgressions) { week in
                        if let exercise = findExercise(week: week) {
                            ProgressDataCell(exercise: exercise, width: dataColumnWidth)
                        } else {
                            // No data for this week
                            Text("-")
                                .font(.subheadline)
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(width: dataColumnWidth)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.1))
                        }
                    }
                }
            }
        }
    }
    
    // Find exercise data for a specific week
    private func findExercise(week: WeeklyProgression) -> ExerciseProgress? {
        return week.exercises.first { $0.exerciseName == exerciseName }
    }
}

struct ProgressDataCell: View {
    let exercise: ExerciseProgress
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            // Weight
            if let weight = exercise.maxWeight {
                Text("\(Int(weight))lbs")
                    .font(.subheadline.bold())
                    .foregroundColor(cellTextColor)
            } else {
                Text("-")
                    .font(.subheadline)
                    .foregroundColor(.gymtimeTextSecondary)
            }
            
            // Sets/Reps
            if let bestSet = exercise.bestSet {
                Text("\(bestSet.reps)r")
                    .font(.caption)
                    .foregroundColor(.gymtimeTextSecondary)
            }
        }
        .frame(width: width)
        .padding(.vertical, 8)
        .background(cellBackgroundColor)
    }
    
    // Dynamic cell background color based on improvement
    private var cellBackgroundColor: Color {
        if exercise.isImprovement {
            return Color.green.opacity(0.15)
        }
        return Color.black.opacity(0.1)
    }
    
    // Dynamic text color based on improvement
    private var cellTextColor: Color {
        if exercise.isImprovement {
            return .green
        }
        return .gymtimeText
    }
}
```

#### 2.2 ProgressionCard (gymtime/Features/Profile/Views/Components/ProgressionCard.swift)

```swift
// 📄 Card showing a summary of the user's workout progression

import SwiftUI

struct ProgressionCard: View {
    @ObservedObject var viewModel: ProgressionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("STRENGTH PROGRESSION")
                    .font(.headline)
                    .foregroundColor(.gymtimeTextSecondary)
                
                Spacer()
                
                NavigationLink(destination: ProgressionView()) {
                    Text("View All")
                        .font(.caption.bold())
                        .foregroundColor(.gymtimeAccent)
                }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.gymtimeText)
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
            } else if viewModel.weeklyProgressions.isEmpty {
                Text("No workout data found yet")
                    .font(.caption)
                    .foregroundColor(.gymtimeTextSecondary)
                    .padding(.vertical, 8)
            } else {
                // Show the top 3 exercises with the most improvement
                VStack(spacing: 12) {
                    ForEach(topExercises(), id: \.exerciseName) { exercise in
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.subheadline)
                                .foregroundColor(.gymtimeText)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let weight = exercise.maxWeight {
                                Text("\(Int(weight))lbs")
                                    .font(.subheadline.bold())
                                    .foregroundColor(exercise.isImprovement ? .green : .gymtimeText)
                            }
                            
                            if exercise.isImprovement {
                                Text("+\(Int(exercise.improvementPercentage))%")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onAppear {
            if viewModel.weeklyProgressions.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.fetchWorkoutProgression()
                }
            }
        }
    }
    
    // Get top exercises with the most improvement
    private func topExercises() -> [ExerciseProgress] {
        guard !viewModel.weeklyProgressions.isEmpty else { return [] }
        
        // Get exercises from the most recent week
        let exercises = viewModel.weeklyProgressions[0].exercises
        
        // Filter for exercises with improvements and sort by improvement percentage
        return exercises
            .filter { $0.isImprovement }
            .sorted { $0.improvementPercentage > $1.improvementPercentage }
            .prefix(3) // Take top 3
            .map { $0 }
    }
}
```

### 3. Update ProfileView Integration

#### 3.1 Update ProfileView (gymtime/Features/Profile/Views/ProfileView.swift)

```swift
// Add ProgressionViewModel to ProfileView
@StateObject private var progressionViewModel = ProgressionViewModel()

// Add ProgressionCard to the ProfileView's VStack, after the Stats Grid:
// Stats Grid
LazyVGrid(columns: [
    GridItem(.flexible()),
    GridItem(.flexible())
], spacing: 16) {
    // ... existing code ...
}
.padding(.horizontal)

// Add Progression Card
ProgressionCard(viewModel: progressionViewModel)
    .padding(.horizontal)

// ... rest of the existing code ...
```

### 4. Update ProfileCoordinator

If your ProfileCoordinator handles navigation in the Profile section, ensure it includes navigation to the ProgressionView.

### 5. Update Color Assets (if needed)

If you need additional colors for highlighting improvements, add them to your Color assets.

### 6. Testing

1. Test with real workout data to ensure proper data fetching and processing
2. Verify that the progression table displays correctly
3. Test navigation from Profile to full ProgressionView
4. Confirm proper highlighting of improvements

## Future Enhancements

1. Add filtering options by muscle group or exercise type
2. Implement charts/graphs for visual representation
3. Add ability to set goals for specific exercises
4. Include more detailed progression analytics (volume, frequency, etc.)

## Notes

- The implementation utilizes existing WorkoutEntry model for data
- Weekly progression is calculated by comparing max weights and best sets
- Improvements are highlighted with green color coding
- Navigation from Profile summary to detailed view follows the app's existing patterns 