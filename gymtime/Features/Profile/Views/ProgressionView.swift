// 📄 Displays the user's workout progression over time

import SwiftUI

struct ProgressionView: View {
    @StateObject var viewModel = ProgressionViewModel()
    @State private var appearAnimation = false
    
    // Column width constraints
    private let exerciseColumnWidth: CGFloat = 120
    private let dataColumnWidth: CGFloat = 80
    // Fixed height for all cells to ensure consistency
    private let cellHeight: CGFloat = 60
    
    // Default exercises for empty state
    private let defaultExercises = [
        "Ab Workout",
        "Abs",
        "Arnold Press",
        "Assault Bike",
        "Atg Split Squat",
        "Barbell Bicep Curl",
        "Barbell Rows",
        "Bench Press",
        "Bicep Curl",
        "Bicep Curls",
        "Cable Rows"
    ]
    
    var body: some View {
        ZStack {  // Wrap in ZStack to allow overlay
            VStack(spacing: 0) {
                if let error = viewModel.error {
                    VStack {
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
                    }
                } else {
                    // Column-based table with synchronized scrolling
                    VStack(spacing: 0) {
                        // FIXED HEADER ROW - outside the ScrollView
                        HStack(spacing: 0) {
                            // Fixed exercise header
                            Text("Exercise")
                                .font(.caption.bold())
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(width: exerciseColumnWidth, alignment: .leading)
                                .frame(height: cellHeight)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.3))
                            
                            // Horizontal scrollable week headers
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    if viewModel.weeklyProgressions.isEmpty {
                                        // Show default week headers if no data
                                        ForEach(0..<4) { weekOffset in
                                            let dates = getDefaultWeekDates(weekOffset: weekOffset)
                                            Text(dates)
                                                .font(.caption.bold())
                                                .foregroundColor(.gymtimeTextSecondary)
                                                .frame(width: dataColumnWidth)
                                                .frame(height: cellHeight)
                                                .background(Color.black.opacity(0.3))
                                        }
                                    } else {
                                        ForEach(viewModel.weeklyProgressions) { week in
                                            Text(week.weekLabel)
                                                .font(.caption.bold())
                                                .foregroundColor(.gymtimeTextSecondary)
                                                .frame(width: dataColumnWidth)
                                                .frame(height: cellHeight)
                                                .background(Color.black.opacity(0.3))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add vertical ScrollView for main content
                        ScrollView(.vertical, showsIndicators: true) {
                            // MAIN CONTENT AREA with fixed exercise column and scrollable data
                            HStack(spacing: 0) {
                                // Fixed exercise names column
                                VStack(spacing: 0) {
                                    if viewModel.weeklyProgressions.isEmpty {
                                        ForEach(defaultExercises, id: \.self) { exerciseName in
                                            Text(exerciseName)
                                                .font(.subheadline)
                                                .foregroundColor(.gymtimeText)
                                                .frame(width: exerciseColumnWidth, alignment: .leading)
                                                .frame(height: cellHeight)
                                                .padding(.horizontal, 8)
                                                .background(Color.black.opacity(0.15))
                                        }
                                    } else {
                                        ForEach(getUniqueExercises(), id: \.self) { exerciseName in
                                            Text(exerciseName)
                                                .font(.subheadline)
                                                .foregroundColor(.gymtimeText)
                                                .frame(width: exerciseColumnWidth, alignment: .leading)
                                                .frame(height: cellHeight)
                                                .padding(.horizontal, 8)
                                                .background(Color.black.opacity(0.15))
                                        }
                                    }
                                }
                                
                                // SINGLE HORIZONTAL SCROLLVIEW for all data columns
                                ScrollView(.horizontal, showsIndicators: false) {
                                    // HStack of week columns
                                    HStack(spacing: 0) {
                                        if viewModel.weeklyProgressions.isEmpty {
                                            // Show empty cells for default exercises
                                            ForEach(0..<4) { _ in
                                                VStack(spacing: 0) {
                                                    ForEach(defaultExercises, id: \.self) { _ in
                                                        Text("-")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gymtimeTextSecondary)
                                                            .frame(width: dataColumnWidth)
                                                            .frame(height: cellHeight)
                                                            .background(Color.black.opacity(0.1))
                                                    }
                                                }
                                            }
                                        } else {
                                            ForEach(viewModel.weeklyProgressions) { week in
                                                VStack(spacing: 0) {
                                                    ForEach(getUniqueExercises(), id: \.self) { exerciseName in
                                                        if let exercise = findExercise(week: week, exerciseName: exerciseName) {
                                                            ProgressDataCell(
                                                                exercise: exercise,
                                                                width: dataColumnWidth,
                                                                height: cellHeight
                                                            )
                                                        } else {
                                                            Text("-")
                                                                .font(.subheadline)
                                                                .foregroundColor(.gymtimeTextSecondary)
                                                                .frame(width: dataColumnWidth)
                                                                .frame(height: cellHeight)
                                                                .background(Color.black.opacity(0.1))
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .opacity(viewModel.weeklyProgressions.isEmpty ? 0.3 : 1) // Fade the chart when empty
                }
            }
            
            // Overlay message when no workouts
            if viewModel.weeklyProgressions.isEmpty && viewModel.hasAttemptedFetch {
                VStack {
                    Text("This chart tracks your weekly progress.")
                        .font(.headline)
                        .foregroundColor(.gymtimeText)
                    Text("Log workouts to get started.")
                        .font(.subheadline)
                        .foregroundColor(.gymtimeTextSecondary)
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
        .background(Color.gymtimeBackground)
        .navigationBarTitle("Progression", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.fetchWorkoutProgression()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gymtimeAccent)
                }
            }
        }
        .onAppear {
            // Trigger the appear animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appearAnimation = true
            }
            
            // Load data if needed
            if viewModel.weeklyProgressions.isEmpty {
                Task {
                    await viewModel.fetchWorkoutProgression()
                }
            }
        }
    }
    
    // Helper to get default week date ranges for empty state
    private func getDefaultWeekDates(weekOffset: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
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
    
    // Find exercise data for a specific week and exercise name
    private func findExercise(week: WeeklyProgression, exerciseName: String) -> ExerciseProgress? {
        return week.exercises.first { $0.exerciseName == exerciseName }
    }
}

// MARK: - Supporting Views

struct ProgressDataCell: View {
    let exercise: ExerciseProgress
    let width: CGFloat
    let height: CGFloat
    
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
            
            // Sets/Reps - Display both sets and reps when available
            if let bestSet = exercise.bestSet {
                if let sets = bestSet.sets {
                    Text("\(sets)x\(bestSet.reps)")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                } else {
                    Text("\(bestSet.reps)r")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                }
            }
        }
        .frame(width: width)
        .frame(height: height)
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