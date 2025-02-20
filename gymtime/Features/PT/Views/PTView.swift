// 📄 Displays the user's body status and recovery information

import SwiftUI

struct PTView: View {
    @StateObject var viewModel: PTViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Muscles to Work Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Muscles to Work")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    
                    // Debug Info for Testing
                    if let analysis = viewModel.analysisResults {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Push/Pull Ratio: \(analysis.pushPullRatio, specifier: "%.2f")")
                                .foregroundColor(viewModel.isPushPullBalanced ? .green : .red)
                            
                            Text("Warnings:")
                                .font(.headline)
                            ForEach(viewModel.warnings, id: \.self) { warning in
                                Text("• \(warning)")
                                    .foregroundColor(.red)
                            }
                            
                            Text("Recommendations:")
                                .font(.headline)
                            ForEach(viewModel.recommendations, id: \.self) { recommendation in
                                Text("• \(recommendation)")
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Muscle Group Scores:")
                                .font(.headline)
                            ForEach(WorkoutAnalysis.knownMuscleGroups, id: \.self) { group in
                                HStack {
                                    Text(group.capitalized)
                                    Spacer()
                                    Text("\(viewModel.strengthScore(for: group), specifier: "%.0f")")
                                        .foregroundColor(viewModel.needsAttention(group) ? .red : .green)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding(.top)
        }
        .background(Color.black)
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

#Preview {
    PTView(viewModel: PTViewModel.preview)
} 