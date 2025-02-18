// 📄 Displays workout data in a clean, organized table format

import SwiftUI

struct WorkoutTableView: View {
    @Binding var workouts: [WorkoutEntry]
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.3  // Increased since we removed date
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.1
    private let repsWidth: CGFloat = 0.1
    private let notesWidth: CGFloat = 0.35    // Increased for better note visibility
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("EXERCISE")
                        .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
                    Text("WEIGHT")
                        .frame(width: UIScreen.main.bounds.width * weightWidth)
                    Text("SETS")
                        .frame(width: UIScreen.main.bounds.width * setsWidth)
                    Text("REPS")
                        .frame(width: UIScreen.main.bounds.width * repsWidth)
                    Text("NOTES")
                        .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gymtimeTextSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.3))
                
                // Table Content
                ScrollView {
                    VStack(spacing: 0) {
                        if workouts.isEmpty {
                            Text("No workouts recorded yet")
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(workouts) { workout in
                                WorkoutRow(
                                    exercise: workout.exercise,
                                    weight: workout.weight.map { "\($0) lb" } ?? "-",
                                    sets: workout.sets.map { "\($0)" } ?? "-",
                                    reps: workout.reps.map { "\($0)" } ?? "-",
                                    notes: workout.notes ?? "",
                                    exerciseWidth: exerciseWidth,
                                    weightWidth: weightWidth,
                                    setsWidth: setsWidth,
                                    repsWidth: repsWidth,
                                    notesWidth: notesWidth
                                )
                                
                                if workout.id != workouts.last?.id {
                                    Divider()
                                        .background(Color.gymtimeTextSecondary.opacity(0.2))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100) // Increased padding to account for button + nav bar
                }
            }
            .background(Color.gymtimeBackground)
            
            // Record Workout Button
            Button(action: {
                // Action will be implemented later
            }) {
                Text("Record Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 40)
                    .padding(.vertical, 16)
                    .background(Color.gymtimeAccent)
                    .cornerRadius(12)
            }
            .padding(.bottom, 65) // Adjusted to sit above nav bar
            .zIndex(1) // Ensure button stays above content
        }
    }
}

struct WorkoutRow: View {
    let exercise: String
    let weight: String
    let sets: String
    let reps: String
    let notes: String
    
    let exerciseWidth: CGFloat
    let weightWidth: CGFloat
    let setsWidth: CGFloat
    let repsWidth: CGFloat
    let notesWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            Text(exercise)
                .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
            Text(weight)
                .frame(width: UIScreen.main.bounds.width * weightWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(sets)
                .frame(width: UIScreen.main.bounds.width * setsWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(reps)
                .frame(width: UIScreen.main.bounds.width * repsWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(notes)
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
        }
        .foregroundColor(.gymtimeText)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)  // Updated to match header padding
    }
} 