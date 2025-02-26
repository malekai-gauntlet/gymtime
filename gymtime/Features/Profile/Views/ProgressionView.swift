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