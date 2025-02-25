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
    // Add namespace for scroll position identification
    @Namespace private var muscleGroupNamespace
    
    // Get today's date for the header
    private var formattedDate: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: today)
        
        // Add ordinal suffix (st, nd, rd, th)
        let day = Calendar.current.component(.day, from: today)
        let suffix = dayOrdinalSuffix(for: day)
        
        return dateStr + suffix
    }
    
    // Helper to get ordinal suffix for day number
    private func dayOrdinalSuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
    
    // Helper to format a relative date as "X days ago"
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDate = calendar.startOfDay(for: date)
        
        if let days = calendar.dateComponents([.day], from: workoutDate, to: today).day {
            switch days {
            case 0:
                return "Today"
            case 1:
                return "Yesterday"
            default:
                return "\(days) days ago"
            }
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
    
    // Helper to format the workout date as "MMM d" (e.g., "Feb 25")
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {  // Wrap in ZStack to overlay SwipeArea
                VStack(spacing: 0) {
                    // Today's Date
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gymtimeTextSecondary)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    
                    // Muscle Group Toggle Row
                    ScrollViewReader { scrollProxy in
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
                                    // Add ID for ScrollViewReader to target
                                    .id(group)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color.black)
                        // Scroll to selected muscle group whenever it changes
                        .onChange(of: viewModel.selectedMuscleGroup) { newGroup in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(newGroup, anchor: .center)
                            }
                        }
                        // Also scroll on initial appearance
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(viewModel.selectedMuscleGroup, anchor: .center)
                            }
                        }
                    }
                    
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
                                    
                                    VStack(spacing: 8) {
                                        // Top line with date
                                        HStack {
                                            if let weight = workout.weight {
                                                Text("\(Int(weight))lbs")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.gymtimeAccent)
                                            }
                                            
                                            Spacer()
                                            
                                            // Date in top right
                                            Text(formatWorkoutDate(workout.date))
                                                .font(.system(size: 14))
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
                                        
                                        // Bottom line with sets/reps and days ago
                                        HStack {
                                            if let sets = workout.sets, let reps = workout.reps {
                                                Text("\(sets) sets × \(reps) reps")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gymtimeTextSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Relative time (Today, Yesterday, X days ago)
                                            Text(relativeDateString(from: workout.date))
                                                .font(.system(size: 14))
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
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
                        .background(Color.black)
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