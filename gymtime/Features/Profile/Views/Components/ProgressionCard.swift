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
                let topExercises = getTopExercises()
                if topExercises.isEmpty {
                    Text("Keep logging workouts to see your progress!")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(topExercises, id: \.exerciseName) { exercise in
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
                                
                                if exercise.isImprovement, exercise.improvementPercentage > 0 {
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
    private func getTopExercises() -> [ExerciseProgress] {
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