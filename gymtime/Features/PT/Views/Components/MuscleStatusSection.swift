// 📄 Component for displaying muscle status sections (overworked, underworked, etc.)

import SwiftUI

struct MuscleStatusSection: View {
    let title: String
    let subtitle: String
    let muscles: [(name: String, score: Double, warning: String?)]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Muscle List
            VStack(spacing: 12) {
                ForEach(muscles, id: \.name) { muscle in
                    HStack(spacing: 16) {
                        // Muscle Icon and Name
                        HStack(spacing: 12) {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .foregroundColor(accentColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(muscle.name.capitalized)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if let warning = muscle.warning {
                                    Text(warning)
                                        .font(.caption)
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Score
                        Text("\(Int(muscle.score))")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(accentColor)
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