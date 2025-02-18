// 📄 Displays the user's body status and recovery information

import SwiftUI

struct PTView: View {
    @State private var selectedTab = "Results"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Top Toggle
                HStack(spacing: 20) {
                    Button(action: { selectedTab = "Results" }) {
                        Text("Results")
                            .foregroundColor(selectedTab == "Results" ? .gymtimeText : .gymtimeTextSecondary)
                            .font(.headline)
                    }
                    
                    Button(action: { selectedTab = "Recovery" }) {
                        Text("Recovery")
                            .foregroundColor(selectedTab == "Recovery" ? .gymtimeText : .gymtimeTextSecondary)
                            .font(.headline)
                    }
                }
                .padding(.top)
                
                // Stats Section
                HStack(spacing: 40) {
                    // Days Since Last Workout
                    VStack(spacing: 8) {
                        Text("0")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.gymtimeText)
                        Text("DAYS SINCE YOUR\nLAST WORKOUT")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gymtimeTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Fresh Muscle Groups
                    VStack(spacing: 8) {
                        Text("10")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.gymtimeText)
                        Text("FRESH MUSCLE\nGROUPS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gymtimeTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                // Body Figure
                ZStack {
                    // Body silhouette placeholder
                    Image(systemName: "figure.stand")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 400)
                        .foregroundColor(Color.gray.opacity(0.3))
                }
                .padding()
                
                Spacer()
            }
            .background(Color.gymtimeBackground)
        }
    }
}

#Preview {
    PTView()
} 