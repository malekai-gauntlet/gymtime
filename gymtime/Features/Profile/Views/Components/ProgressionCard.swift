// 📄 Card showing a summary of the user's workout progression

import SwiftUI

struct ProgressionCard: View {
    @ObservedObject var viewModel: ProgressionViewModel
    @State private var hasInitiatedLoad = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    // Call-to-action styled like a StatCard
                    NavigationLink(destination: ProgressionView()) {
                        VStack(spacing: 8) {
                            // Title - matching StatCard title format
                            Text("YOUR WORKOUT CHART")
                                .font(.caption)
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Chart icon - matching StatCard value size
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.gymtimeText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Subtitle - matching StatCard subtitle format
                            Text("Tap to view your workout progression.")
                                .font(.caption)
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        // Only load data when the card becomes visible
        .onAppear {
            if !hasInitiatedLoad {
                hasInitiatedLoad = true
                // Delay the data fetch slightly to prioritize UI rendering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        await viewModel.fetchWorkoutProgression()
                    }
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