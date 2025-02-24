// 📄 Displays the user's benchmark weights for different exercises

import SwiftUI

struct WeightsView: View {
    @ObservedObject var viewModel: WeightsViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Muscle Group Toggle Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(WeightsViewModel.muscleGroups, id: \.self) { group in
                            Button(action: {
                                viewModel.selectMuscleGroup(group)
                            }) {
                                Text(group)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        group == viewModel.selectedMuscleGroup
                                        ? Color.gymtimeAccent
                                        : Color.gray.opacity(0.2)
                                    )
                                    .foregroundColor(
                                        group == viewModel.selectedMuscleGroup
                                        ? .white
                                        : .gymtimeTextSecondary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.black.opacity(0.3))
                
                // Workout List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.workouts.isEmpty {
                    Spacer()
                    Text("No workouts found for \(viewModel.selectedMuscleGroup)")
                        .foregroundColor(.gymtimeTextSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.workouts) { workout in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(workout.exercise)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack(alignment: .center, spacing: 16) {
                                    if let weight = workout.weight {
                                        Text("\(Int(weight))lbs")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.gymtimeAccent)
                                    }
                                    
                                    if let sets = workout.sets, let reps = workout.reps {
                                        Text("\(sets) sets × \(reps) reps")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gymtimeTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(workout.date.formatted(date: .numeric, time: .omitted))
                                        .font(.system(size: 14))
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.15))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.gymtimeBackground)
            .navigationBarTitle("Weights", displayMode: .inline)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Text(viewModel.error ?? "Unknown error")
        }
    }
} 