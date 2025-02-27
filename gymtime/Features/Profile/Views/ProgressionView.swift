// 📄 Displays the user's workout progression over time

import SwiftUI

struct ProgressionView: View {
    @StateObject private var viewModel = ProgressionViewModel()
    // Add state for animation control
    @State private var appearAnimation = false
    
    // Column width constraints
    private let exerciseColumnWidth: CGFloat = 120
    private let dataColumnWidth: CGFloat = 80
    // Fixed height for all cells to ensure consistency
    private let cellHeight: CGFloat = 60
    // Fixed padding for all cells
    private let cellVerticalPadding: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                // Enhanced loading view
                VStack {
                    Spacer()
                    
                    // Loading card with gradient background - now full width
                    VStack(spacing: 20) {
                        // Animated dumbbell icon
                        ZStack {
                            // Pulse animation for icon background
                            Circle()
                                .fill(Color.gymtimeAccent.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true),
                                    value: UUID() // Force animation to run
                                )
                            
                            // Dumbbell icon
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gymtimeAccent)
                                .rotationEffect(.degrees(viewModel.isLoading ? 15 : -15))
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: viewModel.isLoading
                                )
                        }
                        
                        // Progress indicator
                        ProgressView()
                            .tint(.gymtimeText)
                            .scaleEffect(1.2)
                            .padding(.top, 5)
                        
                        // Loading text
                        Text("Loading progression data...")
                            .font(.headline)
                            .foregroundColor(.gymtimeText)
                        
                        Text("Analyzing your strength gains")
                            .font(.subheadline)
                            .foregroundColor(.gymtimeTextSecondary)
                            .padding(.top, -5)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 25)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.gymtimeAccent.opacity(0.3), lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .transition(.opacity)
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
                .transition(.opacity)
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
                .transition(.opacity)
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
                    
                    // Add vertical ScrollView for main content
                    ScrollView(.vertical, showsIndicators: true) {
                        // MAIN CONTENT AREA with fixed exercise column and scrollable data
                        HStack(spacing: 0) {
                            // Fixed exercise names column
                            VStack(spacing: 0) {
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
                            
                            // SINGLE HORIZONTAL SCROLLVIEW for all data columns
                            ScrollView(.horizontal, showsIndicators: false) {
                                // HStack of week columns
                                HStack(spacing: 0) {
                                    // Each week gets a column of exercise data
                                    ForEach(viewModel.weeklyProgressions) { week in
                                        // Column of cells for this week
                                        VStack(spacing: 0) {
                                            // Row for each exercise
                                            ForEach(getUniqueExercises(), id: \.self) { exerciseName in
                                                if let exercise = findExercise(week: week, exerciseName: exerciseName) {
                                                    ProgressDataCell(
                                                        exercise: exercise,
                                                        width: dataColumnWidth,
                                                        height: cellHeight
                                                    )
                                                } else {
                                                    // No data for this week/exercise
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
                .opacity(appearAnimation ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: appearAnimation)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(Color.gymtimeBackground)
        .navigationBarTitle("Progression", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            // Reset appear animation when refreshing
            appearAnimation = false
            Task {
                await viewModel.fetchWorkoutProgression()
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.gymtimeAccent)
        })
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .onAppear {
            // Trigger the appear animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appearAnimation = true
            }
        }
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