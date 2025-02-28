// 📄 Full-screen menu for adding workouts and viewing suggestions

import SwiftUI

// Tab options for the workout menu
enum WorkoutMenuTab {
    case history
    case library
}

// Sort methods for history tab
enum HistorySortMethod {
    case mostRecent
    case alphabetical
}

struct WorkoutMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Selected tab state
    @State private var selectedTab: WorkoutMenuTab = .history
    
    // Track which workouts have been added
    @State private var addedWorkouts: Set<UUID> = []
    // Track which library exercises have been added
    @State private var addedLibraryExercises: Set<UUID> = []
    // Toast notification state
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Loading states
    @State private var isLoadingHistory = true
    @State private var isLoadingLibrary = true
    
    // Sort methods
    @State private var librarySortMethod = LibrarySortMethod.alphabetical
    @State private var historySortMethod = HistorySortMethod.mostRecent
    
    // Track toast timer for proper cancellation
    @State private var toastTimer: DispatchWorkItem?
    
    // Filtered suggestions based on search text
    private var filteredHistoryItems: [WorkoutEntry] {
        if searchText.isEmpty {
            return viewModel.suggestedWorkouts
        } else {
            return viewModel.suggestedWorkouts.filter { workout in
                // Use the fuzzy matching for more lenient search
                viewModel.fuzzyMatch(searchText: searchText, targetString: workout.exercise) ||
                (workout.muscleGroup != nil && viewModel.fuzzyMatch(searchText: searchText, targetString: workout.muscleGroup!))
            }
        }
    }
    
    // Filtered library exercises based on search text
    private var filteredLibraryExercises: [Exercise] {
        viewModel.filterLibraryExercises(searchText: searchText)
    }
    
    // Check if we should show no results message
    private var shouldShowNoResults: Bool {
        !searchText.isEmpty && 
        ((selectedTab == .history && filteredHistoryItems.isEmpty) || 
         (selectedTab == .library && filteredLibraryExercises.isEmpty))
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
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        // History tab
                        Button(action: {
                            withAnimation {
                                selectedTab = .history
                            }
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 5) {
                                    Text("History")
                                        .font(.headline)
                                        .foregroundColor(selectedTab == .history ? .gymtimeText : .gymtimeTextSecondary)
                                    
                                    // Show count badge when searching and not on this tab
                                    if !searchText.isEmpty && selectedTab != .history && !filteredHistoryItems.isEmpty {
                                        Text("(\(filteredHistoryItems.count))")
                                            .font(.caption)
                                            .foregroundColor(.gymtimeAccent)
                                    }
                                }
                                
                                Rectangle()
                                    .fill(selectedTab == .history ? Color.gymtimeAccent : Color.clear)
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Library tab
                        Button(action: {
                            withAnimation {
                                selectedTab = .library
                            }
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 5) {
                                    Text("Library")
                                        .font(.headline)
                                        .foregroundColor(selectedTab == .library ? .gymtimeText : .gymtimeTextSecondary)
                                    
                                    // Show count badge when searching and not on this tab
                                    if !searchText.isEmpty && selectedTab != .library && !filteredLibraryExercises.isEmpty {
                                        Text("(\(filteredLibraryExercises.count))")
                                            .font(.caption)
                                            .foregroundColor(.gymtimeAccent)
                                    }
                                }
                                
                                Rectangle()
                                    .fill(selectedTab == .library ? Color.gymtimeAccent : Color.clear)
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 12)
                    
                    ScrollView {
                        // HISTORY SECTION (formerly SUGGESTIONS)
                        if selectedTab == .history {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                                    Text("History")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gymtimeText)
                            
                                    if !searchText.isEmpty {
                                        Text("(\(filteredHistoryItems.count))")
                                            .font(.subheadline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                    }
                                    
                            Spacer()
                            
                            Menu {
                                Button("Most Recent", action: {
                                    historySortMethod = .mostRecent
                                    sortHistoryItems(by: .mostRecent)
                                })
                                Button("Alphabetical", action: {
                                    historySortMethod = .alphabetical
                                    sortHistoryItems(by: .alphabetical)
                                })
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text(historySortMethodLabel())
                                }
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                                // Workout list - show real history if available, otherwise show placeholders
                            LazyVStack(spacing: 0) {
                                    if isLoadingHistory {
                                    VStack {
                                        Spacer()
                                            ProgressView("Loading history...")
                                        Spacer()
                                    }
                                        .frame(height: 100)
                                } else if viewModel.suggestedWorkouts.isEmpty {
                                        // Show empty state message
                                        VStack(spacing: 16) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gymtimeTextSecondary)
                                            
                                            Text("No workout history yet")
                                                .font(.headline)
                                                .foregroundColor(.gymtimeTextSecondary)
                                            
                                            Text("Your recent workouts will appear here")
                                                .font(.subheadline)
                                                .foregroundColor(.gymtimeTextSecondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 50)
                                    } else if filteredHistoryItems.isEmpty && !searchText.isEmpty {
                                        // Show no results when searching
                                    VStack(spacing: 16) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gymtimeTextSecondary)
                                        
                                            Text("No history items found matching '\(searchText)'")
                                            .font(.headline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 50)
                                } else {
                                        // Show filtered history items
                                        ForEach(filteredHistoryItems) { workout in
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
                                                
                                                // Simplified button with larger tap area
                                                Button(action: {
                                                    // Capture the workout ID immediately
                                                    let workoutID = workout.id
                                                    
                                                    // Perform haptic feedback immediately
                                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                                    generator.impactOccurred()
                                                    
                                                    // Add workout to Supabase
                                                    viewModel.addSuggestionToWorkouts(workout)
                                                    
                                                    // Update UI state with a slight delay to ensure the previous operations complete
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                        // Update local state
                                                        addedWorkouts.insert(workoutID)
                                                        
                                                        // Show toast
                                                        toastMessage = "\(workout.exercise) logged!"
                                                        showToast = true
                                                        
                                                        // Schedule toast hiding
                                                        toastTimer?.cancel()
                                                        let newTimer = DispatchWorkItem {
                                                            withAnimation {
                                                                showToast = false
                                                            }
                                                        }
                                                        toastTimer = newTimer
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: newTimer)
                                                    }
                                                }) {
                                                    Image(systemName: addedWorkouts.contains(workout.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                                        .font(.system(size: 28))
                                                        .foregroundColor(addedWorkouts.contains(workout.id) ? .green : .gymtimeAccent)
                                                        .frame(width: 60, height: 60)
                                                        .contentShape(Rectangle())
                                                }
                                                .buttonStyle(ScaleButtonStyle()) // Add scale animation
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal)
                                            .background(Color.gymtimeBackground)
                                            
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.horizontal)
                                            .onAppear {
                                                print("📍 Row appeared for history item: \(workout.exercise) (ID: \(workout.id))")
                                            }
                                            .id(workout.id)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        
                        // LIBRARY SECTION
                        if selectedTab == .library {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Library")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gymtimeText)
                                    
                                    if !searchText.isEmpty {
                                        Text("(\(filteredLibraryExercises.count))")
                                            .font(.subheadline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button("Alphabetical", action: {
                                            librarySortMethod = .alphabetical
                                            viewModel.sortLibraryExercises(by: .alphabetical)
                                        })
                                        Button("By Muscle Group", action: {
                                            librarySortMethod = .muscleGroup
                                            viewModel.sortLibraryExercises(by: .muscleGroup)
                                        })
                                    } label: {
                                        HStack {
                                            Image(systemName: "line.3.horizontal.decrease")
                                            Text(librarySortMethodLabel())
                                        }
                                        .foregroundColor(.gymtimeTextSecondary)
                                        .padding(8)
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 20)
                                
                                // Library list
                                LazyVStack(spacing: 0) {
                                    if isLoadingLibrary {
                                        VStack {
                                            Spacer()
                                            ProgressView("Loading exercise library...")
                                            Spacer()
                                        }
                                        .frame(height: 100)
                                    } else if filteredLibraryExercises.isEmpty && !shouldShowNoResults {
                                        // Show empty state when no exercises in library (but not when it's due to filtering)
                                        VStack(spacing: 16) {
                                            Image(systemName: "dumbbell")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gymtimeTextSecondary)
                                            
                                            Text("Exercise library is empty")
                                                .font(.headline)
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 50)
                                    } else if filteredLibraryExercises.isEmpty && !searchText.isEmpty {
                                        // Show no results when searching
                                        VStack(spacing: 16) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gymtimeTextSecondary)
                                            
                                            Text("No exercises found matching '\(searchText)'")
                                                .font(.headline)
                                                .foregroundColor(.gymtimeTextSecondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 50)
                                    } else {
                                        // Show filtered library exercises
                                        ForEach(filteredLibraryExercises) { exercise in
                                            ZStack {
                                                // Background for the entire row that handles taps
                                                Button(action: {
                                                    // No action here - we'll handle it in the plus button
                                                }) {
                                                    Rectangle()
                                                        .fill(Color.clear)
                                                        .contentShape(Rectangle())
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                // Actual row content
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(exercise.name)
                                                            .font(.headline)
                                                            .foregroundColor(.gymtimeText)
                                                        
                                                        HStack(spacing: 8) {
                                                            Text(exercise.muscleGroup)
                                                                .font(.subheadline)
                                                                .foregroundColor(.gymtimeTextSecondary)
                                                            
                                                            if let equipment = exercise.equipment {
                                                                Text("• \(equipment)")
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.gymtimeTextSecondary)
                                                            }
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    // Add button
                                                    Button(action: {
                                                        // Capture the exercise ID immediately
                                                        let exerciseID = exercise.id
                                                        
                                                        // Perform haptic feedback immediately
                                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                                        generator.impactOccurred()
                                                        
                                                        // Add exercise to workouts
                                                        viewModel.addLibraryExerciseToWorkouts(exercise)
                                                        
                                                        // Update UI state
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                            // Update local state
                                                            addedLibraryExercises.insert(exerciseID)
                                                            
                                                            // Show toast
                                                            toastMessage = "\(exercise.name) logged!"
                                                            showToast = true
                                                            
                                                            // Schedule toast hiding
                                                            toastTimer?.cancel()
                                                            let newTimer = DispatchWorkItem {
                                                                withAnimation {
                                                                    showToast = false
                                                                }
                                                            }
                                                            toastTimer = newTimer
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: newTimer)
                                                        }
                                                    }) {
                                                        Image(systemName: addedLibraryExercises.contains(exercise.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                                            .font(.system(size: 28))
                                                            .foregroundColor(addedLibraryExercises.contains(exercise.id) ? .green : .gymtimeAccent)
                                                            .frame(width: 60, height: 60)
                                                            .contentShape(Rectangle())
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                                .padding(.vertical, 12)
                                                .padding(.horizontal)
                                            }
                                            .background(Color.gymtimeBackground)
                                            
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.horizontal)
                                                .onAppear {
                                                    print("📍 Row appeared for library exercise: \(exercise.name) (ID: \(exercise.id))")
                                                }
                                                .id(exercise.id) // Ensure each row has a stable identity
                                        }
                                    }
                                }
                            }
                        }
                        
                        // No results message when both tabs have no matches - removed as each tab now has its own message
                    }
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
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("✅ Done button tapped")
                        // Add a small delay to ensure the action completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }) {
                        Text("Done")
                            .foregroundColor(.blue)
                            .frame(minWidth: 60, minHeight: 44) // Increase tap target
                            .contentShape(Rectangle())
                    }
                }
            }
            .onAppear {
                print("📱 WorkoutMenuView appeared")
                Task {
                    // Load suggestions
                    print("🔄 Starting to load history items (suggestions)")
                    isLoadingHistory = true
                    await viewModel.getMoreWorkoutSuggestions()
                    print("✅ Finished loading history items, count: \(viewModel.suggestedWorkouts.count)")
                    isLoadingHistory = false
                    
                    // Load library exercises
                    print("🔄 Starting to load library exercises")
                    isLoadingLibrary = true
                    await viewModel.loadExerciseLibrary()
                    print("✅ Finished loading library exercises, count: \(viewModel.libraryExercises.count)")
                    isLoadingLibrary = false
                }
            }
            .onDisappear {
                print("📱 WorkoutMenuView disappeared")
                toastTimer?.cancel()
            }
            .onChange(of: searchText) { oldText, newText in
                print("🔍 Search text changed: '\(oldText)' -> '\(newText)'")
                print("🔍 Filtered history items count: \(filteredHistoryItems.count)")
                print("🔍 Filtered library count: \(filteredLibraryExercises.count)")
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside of a text field
                isSearchFocused = false
            }
        }
    }
    
    // Helper to get the correct label for the library sort menu
    private func librarySortMethodLabel() -> String {
        switch librarySortMethod {
        case .alphabetical:
            return "Alphabetical"
        case .muscleGroup:
            return "By Muscle Group"
        }
    }
    
    // Helper to get the correct label for the history sort menu
    private func historySortMethodLabel() -> String {
        switch historySortMethod {
        case .mostRecent:
            return "Most Recent"
        case .alphabetical:
            return "Alphabetical"
        }
    }
    
    // Sort history items
    private func sortHistoryItems(by sortMethod: HistorySortMethod) {
        withAnimation {
            switch sortMethod {
            case .mostRecent:
                // We don't need to do anything special since the default order from the API is already most recent
                // But we'll reload to ensure the order is correct
                Task {
                    isLoadingHistory = true
                    await viewModel.getMoreWorkoutSuggestions()
                    isLoadingHistory = false
                }
            case .alphabetical:
                // Sort alphabetically by exercise name
                viewModel.suggestedWorkouts.sort { $0.exercise < $1.exercise }
            }
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