// 📄 Displays the user's benchmark weights for different exercises

import SwiftUI

// SwipeArea view to handle horizontal swipes
struct WeightsSwipeArea: View {
    let onSwipe: (Bool) -> Void // true for right, false for left
    @GestureState private var translation: CGFloat = 0
    private let swipeThreshold: CGFloat = 50
    let canSwipeRight: Bool
    let canSwipeLeft: Bool
    
    var body: some View {
        Rectangle()
            .fill(.clear) // No visible tint
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { gesture in
                        let isRightSwipe = gesture.translation.width > 0
                        if abs(gesture.translation.width) > swipeThreshold {
                            if (isRightSwipe && canSwipeRight) || (!isRightSwipe && canSwipeLeft) {
                                onSwipe(isRightSwipe)
                            }
                        }
                    }
            )
    }
}

struct WeightsView: View {
    @ObservedObject var viewModel: WeightsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {  // Wrap in ZStack to overlay SwipeArea
                VStack(spacing: 0) {
                    // Muscle Group Toggle Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(WeightsViewModel.muscleGroups, id: \.self) { group in
                                Button(action: {
                                    withAnimation {
                                        viewModel.selectMuscleGroup(group)
                                    }
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
                .navigationBarTitle("Recent Weights", displayMode: .inline)
                
                // Add SwipeArea
                GeometryReader { geometry in
                    WeightsSwipeArea(onSwipe: { isRight in
                        let currentIndex = WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if isRight && currentIndex > 0 {
                                // Move to previous group
                                viewModel.selectMuscleGroup(WeightsViewModel.muscleGroups[currentIndex - 1])
                            } else if !isRight && currentIndex < WeightsViewModel.muscleGroups.count - 1 {
                                // Move to next group
                                viewModel.selectMuscleGroup(WeightsViewModel.muscleGroups[currentIndex + 1])
                            }
                        }
                    }, canSwipeRight: WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0 > 0,
                       canSwipeLeft: (WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0) < WeightsViewModel.muscleGroups.count - 1)
                    .frame(height: geometry.size.height - 80) // Subtract toggle bar height + padding
                    .position(x: geometry.size.width / 2, y: (geometry.size.height + 80) / 2) // Center in remaining space
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Text(viewModel.error ?? "Unknown error")
        }
    }
} 