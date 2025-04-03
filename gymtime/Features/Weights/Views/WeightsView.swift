// 📄 Displays the user's benchmark weights for different exercises

import SwiftUI

// Horizontal swipe handler modifier (similar to HomeView implementation)
struct WeightsHorizontalSwipeHandler: ViewModifier {
    let onSwipe: (Bool) -> Void // true for right, false for left
    let canSwipeRight: Bool
    let canSwipeLeft: Bool
    
    // Minimum distance to trigger a horizontal swipe
    private let horizontalThreshold: CGFloat = 50
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture()
                    .onEnded { gesture in
                        let horizontalMovement = abs(gesture.translation.width)
                        let verticalMovement = abs(gesture.translation.height)
                        
                        // Only trigger if primarily horizontal (with bias toward vertical)
                        if horizontalMovement > verticalMovement * 1.2 && 
                           horizontalMovement > horizontalThreshold {
                            let isRightSwipe = gesture.translation.width > 0
                            
                            // Only trigger if swiping in an allowed direction
                            if (isRightSwipe && canSwipeRight) || (!isRightSwipe && canSwipeLeft) {
                                print("👉 Weights horizontal swipe detected: \(isRightSwipe ? "RIGHT" : "LEFT")")
                                onSwipe(isRightSwipe)
                            }
                        }
                    }
            )
    }
}

extension View {
    func weightsHorizontalSwipe(onSwipe: @escaping (Bool) -> Void, canSwipeRight: Bool, canSwipeLeft: Bool) -> some View {
        self.modifier(WeightsHorizontalSwipeHandler(onSwipe: onSwipe, canSwipeRight: canSwipeRight, canSwipeLeft: canSwipeLeft))
    }
}

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

// Add WorkoutListView before WeightsView
struct WorkoutListView: View {
    let workouts: [WorkoutEntry]
    let onWorkoutTapped: ((Date) -> Void)?
    @State private var selectedExercise: String?
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDate = calendar.startOfDay(for: date)
        
        if let days = calendar.dateComponents([.day], from: workoutDate, to: today).day {
            switch days {
            case 0: return "Today"
            case 1: return "Yesterday"
            default: return "\(days) days ago"
            }
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(workouts) { workout in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(workout.exercise)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            HStack {
                                if let weight = workout.weight {
                                    Text("\(Int(weight))lbs")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.gymtimeAccent)
                                }
                                
                                Spacer()
                                
                                Text(formatWorkoutDate(workout.date))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                            
                            HStack {
                                if let sets = workout.sets, let reps = workout.reps {
                                    Text("\(sets) sets × \(reps) reps")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                                
                                Spacer()
                                
                                Text(relativeDateString(from: workout.date))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                            
                            if let notes = workout.notes, !notes.isEmpty {
                                HStack(alignment: .top) {
                                    Text(notes)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.gymtimeTextSecondary)
                                        .italic()
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.15))
                    )
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        selectedExercise = workout.exercise
                    }
                }
                
                Color.clear.frame(height: 20)
            }
            .padding(.vertical, 8)
        }
        .background(Color.black)
        .sheet(item: $selectedExercise) { exercise in
            NavigationView {
                ExerciseHistoryView(
                    exerciseName: exercise,
                    onWorkoutTapped: onWorkoutTapped
                )
            }
        }
    }
}

// Add Identifiable conformance for String to work with sheet
extension String: Identifiable {
    public var id: String { self }
}

struct WeightsView: View {
    @ObservedObject var viewModel: WeightsViewModel
    let onWorkoutTapped: ((Date) -> Void)?
    
    // Add namespace for scroll position identification
    @Namespace private var muscleGroupNamespace
    
    // Tooltip state tracking
    @State private var hasSeenTooltip = false
    @State private var isLoadingTooltipState = true
    @State private var showingTooltip = false
    
    // Feedback modal state
    @State private var showingFeedbackModal = false
    
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
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gymtimeTextSecondary)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    
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
                                    .id(group)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color.black)
                        .onChange(of: viewModel.selectedMuscleGroup) { newGroup in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(newGroup, anchor: .center)
                            }
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(viewModel.selectedMuscleGroup, anchor: .center)
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.workouts.isEmpty {
                        Spacer()
                        Text("No \(viewModel.selectedMuscleGroup) workouts logged yet")
                            .foregroundColor(.gymtimeTextSecondary)
                        Spacer()
                    } else {
                        WorkoutListView(workouts: viewModel.workouts, onWorkoutTapped: onWorkoutTapped)
                            .weightsHorizontalSwipe(
                                onSwipe: { isRight in
                                    let currentIndex = WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if isRight && currentIndex > 0 {
                                            viewModel.selectMuscleGroup(WeightsViewModel.muscleGroups[currentIndex - 1])
                                        } else if !isRight && currentIndex < WeightsViewModel.muscleGroups.count - 1 {
                                            viewModel.selectMuscleGroup(WeightsViewModel.muscleGroups[currentIndex + 1])
                                        }
                                    }
                                },
                                canSwipeRight: WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0 > 0,
                                canSwipeLeft: (WeightsViewModel.muscleGroups.firstIndex(of: viewModel.selectedMuscleGroup) ?? 0) < WeightsViewModel.muscleGroups.count - 1
                            )
                    }
                }
                .background(Color.gymtimeBackground)
                .navigationBarTitle("Recent Weights", displayMode: .inline)
                .zIndex(0)
                .simpleTooltip(
                    isVisible: showingTooltip,
                    title: "Recent Weights",
                    message: "This tab shows your most recent weights for each exercise you do.",
                    onDismiss: {
                        showingTooltip = false
                        if !hasSeenTooltip {
                            Task {
                                do {
                                    let userId = try await supabase.auth.session.user.id
                                    try await supabase
                                        .from("profiles")
                                        .update(["has_seen_weights_tooltip": true])
                                        .eq("id", value: userId)
                                        .execute()
                                    
                                    hasSeenTooltip = true
                                } catch {
                                    print("❌ Error updating weights tooltip state: \(error)")
                                }
                            }
                        }
                    }
                )
                
                // Floating Feedback Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingFeedbackModal = true
                        } label: {
                            Image(systemName: "message.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gymtimeAccent)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16) // Reduced bottom padding to match HomeView plus button
                    }
                }
                .zIndex(1)
            }
        }
        .alert("Have feedback or want a feature?", isPresented: $showingFeedbackModal) {
            Button("Cancel", role: .cancel) {
                showingFeedbackModal = false
            }
            Button("Send Text") {
                if let url = URL(string: "sms:+16128675255&body=Gymtime%20App%20Feature%20Request:%20") {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Feel free to SMS any feedback.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Text(viewModel.error ?? "Unknown error")
        }
        .onAppear {
            Task {
                do {
                    let userId = try await supabase.auth.session.user.id
                    let profile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value
                    
                    hasSeenTooltip = profile.hasSeenWeightsTooltip
                    isLoadingTooltipState = false
                    
                    if !hasSeenTooltip {
                        print("🔍 First time viewing weights tab - showing tooltip")
                        showingTooltip = true
                    }
                } catch {
                    print("❌ Error loading weights tooltip state: \(error)")
                    isLoadingTooltipState = false
                }
            }
        }
    }
} 
