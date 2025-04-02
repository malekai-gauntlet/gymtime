// 📄 Displays historical data and progress for a specific exercise

import SwiftUI
import Supabase

struct ExerciseHistoryView: View {
    let exerciseName: String
    @StateObject private var viewModel: ExerciseHistoryViewModel
    
    init(exerciseName: String) {
        self.exerciseName = exerciseName
        self._viewModel = StateObject(wrappedValue: ExerciseHistoryViewModel(supabase: supabase, exerciseName: exerciseName))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.workouts.isEmpty {
                    Text("No history found for \(exerciseName)")
                        .foregroundColor(.gymtimeTextSecondary)
                        .padding()
                } else {
                    // Simple list of workouts
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.workouts) { workout in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    if let weight = workout.weight {
                                        Text("\(Int(weight))lbs")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.gymtimeAccent)
                                    }
                                    
                                    if let sets = workout.sets, let reps = workout.reps {
                                        Text("\(sets) sets × \(reps) reps")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gymtimeTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatDate(workout.date))
                                        .font(.system(size: 14))
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                                
                                if let notes = workout.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gymtimeTextSecondary)
                                        .italic()
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color.gymtimeBackground)
        .navigationTitle(exerciseName)
    }
} 