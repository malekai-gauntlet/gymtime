// 📄 Component for displaying recommended exercises

import SwiftUI

struct ExerciseRecommendationSection: View {
    struct Exercise {
        let name: String
        let targetMuscles: [String]
        let explanation: String
    }
    
    let exercises: [Exercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Recommended Exercises")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            
            // Exercise List
            VStack(spacing: 12) {
                ForEach(exercises, id: \.name) { exercise in
                    VStack(alignment: .leading, spacing: 12) {
                        // Exercise Name and Icon
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "dumbbell.fill")
                                        .foregroundColor(.blue)
                                )
                            
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        // Target Muscles
                        HStack {
                            Text("Targets:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            ForEach(exercise.targetMuscles, id: \.self) { muscle in
                                Text(muscle.capitalized)
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Explanation
                        Text(exercise.explanation)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
} 