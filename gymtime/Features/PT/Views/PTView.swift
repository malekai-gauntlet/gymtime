// 📄 Displays the user's body status and recovery information

import SwiftUI

struct PTView: View {
    @StateObject var viewModel: PTViewModel
    
    var body: some View {
        VStack(spacing: 0) {
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
                        
                        // Original Muscle Group Cards
                        VStack(spacing: 12) {
                            MuscleGroupCard(title: "Push Muscles", strength: "\(Int(viewModel.strengthScore(for: "chest")))")
                            MuscleGroupCard(title: "Pull Muscles", strength: "\(Int(viewModel.strengthScore(for: "back")))")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .background(Color.black)
    }
}

struct MuscleGroupCard: View {
    let title: String
    let strength: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.callout.weight(.medium))
                
                Text("\(strength) mSTRENGTH")
                    .foregroundColor(.gray)
                    .font(.callout.weight(.medium))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    PTView(viewModel: PTViewModel.preview)
} 