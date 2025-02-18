// 📄 Displays workout data in a clean, organized table format

import SwiftUI

struct WorkoutTableView: View {
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.3  // Increased since we removed date
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.1
    private let repsWidth: CGFloat = 0.1
    private let notesWidth: CGFloat = 0.35    // Increased for better note visibility
    
    var body: some View {
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
            .padding(.horizontal, 20)  // Increased horizontal padding to match calendar
            .background(Color.black.opacity(0.3))
            
            // Table Content
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        WorkoutRow(
                            exercise: "Shoulder Press",
                            weight: "35 lb",
                            sets: "3",
                            reps: "5",
                            notes: "Felt strong.",
                            exerciseWidth: exerciseWidth,
                            weightWidth: weightWidth,
                            setsWidth: setsWidth,
                            repsWidth: repsWidth,
                            notesWidth: notesWidth
                        )
                        if index < 3 {
                            Divider()
                                .background(Color.gymtimeTextSecondary.opacity(0.2))
                        }
                    }
                }
            }
        }
        .background(Color.gymtimeBackground)
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
        .padding(.horizontal, 30)  // Increased horizontal padding to match calendar
    }
} 
