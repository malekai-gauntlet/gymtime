// 📄 Full-screen menu for adding workouts and viewing suggestions

import SwiftUI

struct WorkoutMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Track which workouts have been added
    @State private var addedWorkouts: Set<UUID> = []
    // Toast notification state
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Loading state
    @State private var isLoading = true
    
    // Track toast timer for proper cancellation
    @State private var toastTimer: DispatchWorkItem?
    
    // Filtered suggestions based on search text
    private var filteredSuggestions: [WorkoutEntry] {
        if searchText.isEmpty {
            return viewModel.suggestedWorkouts
        } else {
            return viewModel.suggestedWorkouts.filter { workout in
                workout.exercise.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gymtimeTextSecondary)
                        
                        TextField("Search for a workout", text: $searchText)
                            .focused($isSearchFocused)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // History section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Suggestions")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gymtimeText)
                            
                            Spacer()
                            
                            Menu {
                                Button("Most Recent", action: {})
                                Button("Most Used", action: {})
                                Button("Alphabetical", action: {})
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Most Recent")
                                }
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Workout list - show real suggestions if available, otherwise show placeholders
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if isLoading {
                                    VStack {
                                        Spacer()
                                        ProgressView("Loading suggestions...")
                                        Spacer()
                                    }
                                } else if viewModel.suggestedWorkouts.isEmpty {
                                    // Show placeholders if no suggestions are available
                                    ForEach(0..<5, id: \.self) { index in
                                        WorkoutSuggestionRow(index: index)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal)
                                            .background(Color.gymtimeBackground)
                                        
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                            .padding(.horizontal)
                                    }
                                } else if filteredSuggestions.isEmpty && !searchText.isEmpty {
                                    // Show no results message when search has no matches
                                    VStack(spacing: 16) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gymtimeTextSecondary)
                                        
                                        Text("No workouts found matching '\(searchText)'")
                                            .font(.headline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 50)
                                } else {
                                    // Show filtered suggestions
                                    ForEach(filteredSuggestions) { workout in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(workout.exercise)
                                                    .font(.headline)
                                                    .foregroundColor(.gymtimeText)
                                                
                                                HStack(spacing: 8) {
                                                    if let weight = workout.weight {
                                                        Text("\(Int(weight)) lbs")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gymtimeTextSecondary)
                                                    }
                                                    
                                                    if let sets = workout.sets, let reps = workout.reps {
                                                        Text("\(sets)×\(reps)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gymtimeTextSecondary)
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                // Cancel any previous timer
                                                toastTimer?.cancel()
                                                
                                                // Create new timer
                                                let newTimer = DispatchWorkItem {
                                                    withAnimation {
                                                        showToast = false
                                                    }
                                                }
                                                toastTimer = newTimer
                                                
                                                // Show toast
                                                withAnimation {
                                                    toastMessage = "\(workout.exercise) logged!"
                                                    showToast = true
                                                }
                                                
                                                // Schedule hiding
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: newTimer)
                                                
                                                // Add haptic feedback
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                
                                                // Add workout without dismissing the menu
                                                viewModel.addSuggestionToWorkouts(workout)
                                                
                                                // Mark this workout as added
                                                addedWorkouts.insert(workout.id)
                                            }) {
                                                // Wrap in ZStack to create larger tap area
                                                ZStack {
                                                    // Invisible larger tap area
                                                    Color.clear
                                                        .frame(width: 60, height: 60)
                                                    
                                                    // The actual button image
                                                    Image(systemName: addedWorkouts.contains(workout.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                                        .font(.system(size: 28))
                                                        .foregroundColor(addedWorkouts.contains(workout.id) ? .green : .gymtimeAccent)
                                                }
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal)
                                        .background(Color.gymtimeBackground)
                                        
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .background(Color.gymtimeBackground)
                
                // Toast notification
                if showToast {
                    VStack {
                        Spacer()
                        
                        Text(toastMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                Task {
                    isLoading = true
                    await viewModel.getMoreWorkoutSuggestions()
                    isLoading = false
                }
            }
            .onDisappear {
                // Cancel any pending toast timer
                toastTimer?.cancel()
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside of a text field
            isSearchFocused = false
        }
    }
}

// Custom button style for scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Placeholder workout suggestion row for UI design
struct WorkoutSuggestionRow: View {
    let index: Int
    
    // Sample workout data
    private let exercises = ["Bench Press", "Squats", "Deadlift", "Pull-ups", "Shoulder Press"]
    private let weights = [135, 225, 315, 0, 95]
    private let sets = [3, 4, 5, 3, 4]
    private let reps = [10, 8, 5, 12, 10]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercises[index % exercises.count])
                    .font(.headline)
                    .foregroundColor(.gymtimeText)
                
                HStack(spacing: 8) {
                    let weight = weights[index % weights.count]
                    if weight > 0 {
                        Text("\(weight) lbs")
                            .font(.subheadline)
                            .foregroundColor(.gymtimeTextSecondary)
                    }
                    
                    Text("\(sets[index % sets.count])×\(reps[index % reps.count])")
                        .font(.subheadline)
                        .foregroundColor(.gymtimeTextSecondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                print("Add workout tapped")
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gymtimeAccent)
            }
        }
    }
}

#Preview {
    // Create a mock HomeViewModel for preview
    let previewViewModel = HomeViewModel()
    return WorkoutMenuView(viewModel: previewViewModel)
} 