// 📄 Displays the user's body status and recovery information

import SwiftUI

struct PTView: View {
    @StateObject var viewModel: PTViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("Training Analysis")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.gymtimeText)
                            
                            Spacer()
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.gymtimeText)
                            }
                        }
                        
                        if let analysis = viewModel.analysisResults {
                            // Push/Pull Card
                            TrainingStatCard(
                                title: "PUSH/PULL RATIO",
                                value: String(format: "%.2f", analysis.pushPullRatio),
                                subtitle: viewModel.isPushPullBalanced ? "Well balanced" : "Needs attention",
                                color: viewModel.isPushPullBalanced ? .green : .orange
                            )
                            
                            // Warnings Section
                            if !viewModel.warnings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "magnifyingglass.circle.fill")
                                            .foregroundColor(.orange)
                                        Text("Areas to Watch")
                                            .font(.headline)
                                            .foregroundColor(.gymtimeText)
                                    }
                                    
                                    ForEach(viewModel.warnings, id: \.self) { warning in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.gray.opacity(0.6))
                                                .padding(.top, 6)
                                            
                                            Text(warning)
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                            }
                            
                            // Recommendations Section
                            if !viewModel.recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.blue)
                                        Text("Recommendations")
                                            .font(.headline)
                                            .foregroundColor(.gymtimeText)
                                    }
                                    
                                    ForEach(viewModel.recommendations, id: \.self) { recommendation in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.gray.opacity(0.6))
                                                .padding(.top, 6)
                                            
                                            Text(recommendation)
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                            }
                        } else if !viewModel.isLoading && viewModel.error == nil {
                            // Welcome Card
                            VStack(spacing: 24) {
                                VStack(spacing: 16) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gymtimeAccent)
                                    
                                    VStack(spacing: 8) {
                                        Text("Get Started")
                                            .font(.title2.bold())
                                            .foregroundColor(.gymtimeText)
                                        
                                        Text("Log your first workout to receive personalized training insights.")
                                            .font(.subheadline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                
                                Button(action: {
                                    selectedTab = 0  // Switch to Home tab
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Workout")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.gymtimeAccent)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let error = viewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                await viewModel.refreshAnalysis()
            }
            .background(Color.gymtimeBackground)
            .navigationBarTitle("PT", displayMode: .inline)
        }
    }
    
    /* Commented out new implementation for comparison
    private func getOverworkedMuscles(from analysis: WorkoutAnalysis) -> [(name: String, score: Double, warning: String?)]? {
        let overworked = WorkoutAnalysis.knownMuscleGroups.compactMap { group -> (name: String, score: Double, warning: String?)? in
            let status = analysis.muscleGroups[group]
            let score = status?.strengthScore ?? 0
            
            if score > 80 || (status?.trainingCount ?? 0) > analysis.daysAnalyzed / 2 {
                let warning = "High training frequency - consider rest"
                return (group, score, warning)
            }
            return nil
        }
        
        return overworked.isEmpty ? nil : overworked
    }
    
    private func getUnderworkedMuscles(from analysis: WorkoutAnalysis) -> [(name: String, score: Double, warning: String?)]? {
        let underworked = WorkoutAnalysis.knownMuscleGroups.compactMap { group -> (name: String, score: Double, warning: String?)? in
            let status = analysis.muscleGroups[group]
            let score = status?.strengthScore ?? 0
            
            if score < 30 || viewModel.needsAttention(group) {
                let warning = "Not trained recently"
                return (group, score, warning)
            }
            return nil
        }
        
        return underworked.isEmpty ? nil : underworked
    }
    
    private func getExerciseRecommendations(from analysis: WorkoutAnalysis) -> [ExerciseRecommendationSection.Exercise]? {
        let underworkedGroups = Set(WorkoutAnalysis.knownMuscleGroups.filter { viewModel.needsAttention($0) })
        
        guard !underworkedGroups.isEmpty else { return nil }
        
        let recommendations = WorkoutAnalysis.exerciseToMuscleGroups
            .filter { exercise, muscles in
                Set(muscles).intersection(underworkedGroups).count > 0
            }
            .map { exercise, muscles in
                ExerciseRecommendationSection.Exercise(
                    name: exercise,
                    targetMuscles: muscles,
                    explanation: "Targets multiple muscles that need attention"
                )
            }
        
        return recommendations.isEmpty ? nil : recommendations
    }
    */
}

// MARK: - Supporting Views

struct TrainingStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    PTView(viewModel: PTViewModel.preview, selectedTab: .constant(1))
} 