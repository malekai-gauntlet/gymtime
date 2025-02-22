import SwiftUI

struct ProgressView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedMuscleGroup = "Chest"
    @Namespace private var namespace
    
    // Define muscle groups
    private let muscleGroups = [
        "Chest", "Back", "Shoulders", "Arms", "Legs", "Core"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Muscle Group Selection
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMuscleGroup = group
                                        // Scroll to center the selected item
                                        proxy.scrollTo(group, anchor: .center)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(group)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(selectedMuscleGroup == group ? .gymtimeAccent : .gray)
                                        
                                        // Indicator line
                                        Rectangle()
                                            .fill(selectedMuscleGroup == group ? Color.gymtimeAccent : Color.clear)
                                            .frame(height: 2)
                                            .matchedGeometryEffect(id: "underline", in: namespace, isSource: selectedMuscleGroup == group)
                                    }
                                }
                                .id(group)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .background(Color.black.opacity(0.3))
                
                // Main Content Area
                ScrollView {
                    VStack(spacing: 16) {
                        // Placeholder for exercise progress cards
                        ForEach(1...5, id: \.self) { _ in
                            ExerciseProgressCard()
                        }
                    }
                    .padding()
                }
            }
            .background(Color.gymtimeBackground)
            .navigationBarTitle("Progress", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.gymtimeAccent)
                    }
                }
            }
        }
    }
}

// Exercise Progress Card View
struct ExerciseProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bench Press")
                .font(.headline)
                .foregroundColor(.gymtimeText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Record")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                    Text("225 lbs × 5")
                        .font(.title3)
                        .foregroundColor(.gymtimeAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Workout")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                    Text("215 lbs × 8")
                        .font(.title3)
                        .foregroundColor(.gymtimeText)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    ProgressView()
} 