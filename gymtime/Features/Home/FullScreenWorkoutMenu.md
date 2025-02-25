# Full-Screen Workout Menu Implementation

## Overview
This document outlines the steps to implement a full-screen menu that appears when tapping the plus icon in the Gymtime app. The menu will be similar to the iOS contact creation screen and will display workout suggestions similar to MyFitnessPal.

## Implementation Steps

### 1. Create a New View for the Full-Screen Menu

Create a new SwiftUI view called `WorkoutMenuView.swift` that will be presented as a full-screen sheet:

```swift
// 📄 Full-screen menu for adding workouts and viewing suggestions

import SwiftUI

struct WorkoutMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Tab selection state
    @State private var selectedTab = 0
    private let tabs = ["All", "My Workouts", "My Recipes", "My Foods"]
    
    var body: some View {
        NavigationView {
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
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            Text(tabs[index])
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .gymtimeAccent : .gymtimeTextSecondary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 8)
                
                // Active tab indicator
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(Color.gymtimeAccent)
                        .frame(width: UIScreen.main.bounds.width / CGFloat(tabs.count), height: 3)
                        .offset(x: CGFloat(selectedTab) * UIScreen.main.bounds.width / CGFloat(tabs.count))
                        .animation(.spring(), value: selectedTab)
                }
                
                // Quick action buttons
                HStack(spacing: 20) {
                    // Voice logging button
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Voice Log")
                            .font(.headline)
                            .foregroundColor(.gymtimeText)
                        
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .onTapGesture {
                        dismiss()
                        viewModel.toggleRecording()
                    }
                    
                    // Barcode scanning button
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Scan a Barcode")
                            .font(.headline)
                            .foregroundColor(.gymtimeText)
                    }
                    .onTapGesture {
                        // Future barcode scanning functionality
                    }
                }
                .padding(.top, 20)
                
                // History section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("History")
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
                    
                    // Recent workouts list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.suggestedWorkouts) { workout in
                                WorkoutSuggestionRow(workout: workout, viewModel: viewModel)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    .background(Color.gymtimeBackground)
                                    .onTapGesture {
                                        viewModel.addSuggestionToWorkouts(workout)
                                        dismiss()
                                    }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .background(Color.gymtimeBackground)
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
                        // Add any pending workout
                        if let blankWorkout = viewModel.blankWorkoutEntry, !blankWorkout.exercise.isEmpty {
                            viewModel.addWorkout(blankWorkout)
                        }
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// Helper view for workout suggestion rows
struct WorkoutSuggestionRow: View {
    let workout: WorkoutEntry
    let viewModel: HomeViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.exercise)
                    .font(.headline)
                    .foregroundColor(.gymtimeText)
                
                HStack(spacing: 8) {
                    if let weight = workout.weight {
                        Text("\(Int(weight)) cal")
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
                viewModel.addSuggestionToWorkouts(workout)
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gymtimeAccent)
            }
        }
    }
}

#Preview {
    WorkoutMenuView(viewModel: HomeViewModel())
}
```

### 2. Modify HomeViewModel to Support the Menu

Update the `HomeViewModel+Suggestions.swift` file to enhance the suggestions functionality:

```swift
// Add to HomeViewModel+Suggestions.swift

// Get more workout suggestions for the full-screen menu
func getMoreWorkoutSuggestions() async {
    guard let userId = try? await supabase.auth.session.user.id else { return }
    
    do {
        // Get recent workouts for suggestions
        let response: [WorkoutEntry] = try await supabase
            .from("workouts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(20)  // Fetch more for the full menu
            .execute()
            .value
        
        // Remove duplicates based on exercise name
        var uniqueExercises: Set<String> = []
        let suggestions = response
            .filter { workout in
                uniqueExercises.insert(workout.exercise).inserted
            }
            .prefix(10)  // Show more suggestions in the full menu
            .map { $0 }  // Convert ArraySlice back to Array
        
        await MainActor.run {
            withAnimation {
                suggestedWorkouts = suggestions
            }
        }
    } catch {
        print("Error loading suggestions: \(error)")
    }
}
```

### 3. Update WorkoutTableView to Show the Full-Screen Menu

Modify the plus button in `WorkoutTableView.swift` to present the full-screen menu:

```swift
// In WorkoutTableView.swift

// Add this state variable
@State private var showingWorkoutMenu = false

// Replace the existing plus button with:
Button(action: {
    print("Plus button tapped")
    showingWorkoutMenu = true
}) {
    ZStack {
        Circle()
            .fill(Color(.systemGray6))
            .frame(width: 52, height: 52)
            .overlay(
                Circle()
                    .strokeBorder(Color.gymtimeAccent.opacity(0.3), lineWidth: 2)
            )
        Image(systemName: "plus")
            .font(.system(size: 26, weight: .semibold))
            .foregroundColor(.gymtimeAccent)
    }
    .shadow(radius: 3, x: 0, y: 1)
}
.padding(.trailing, 31)
.sheet(isPresented: $showingWorkoutMenu) {
    WorkoutMenuView(viewModel: viewModel)
        .onAppear {
            // Load more suggestions when menu appears
            Task {
                await viewModel.getMoreWorkoutSuggestions()
            }
        }
}
```

### 4. Create a Custom Transition for the Menu

For a more polished experience, add a custom transition to the sheet presentation:

```swift
// Add this extension to a utilities file or at the bottom of WorkoutMenuView.swift

extension View {
    func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.fullScreenCover(
            isPresented: isPresented,
            onDismiss: nil,
            content: content
        )
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: isPresented.wrappedValue)
    }
}
```

### 5. Add Necessary UI Colors and Styles

Ensure the app has the necessary color extensions for consistent styling:

```swift
// Add these to your Color extensions if not already present

extension Color {
    static let gymtimeBackground = Color(UIColor.systemBackground)
    static let gymtimeText = Color(UIColor.label)
    static let gymtimeTextSecondary = Color(UIColor.secondaryLabel)
    static let gymtimeAccent = Color.blue
}
```

## Testing

1. Test the menu appearance by tapping the plus button
2. Verify that suggestions load correctly
3. Test adding a workout from the suggestions
4. Test the search functionality
5. Test the voice recording integration
6. Ensure the menu dismisses properly

## Future Enhancements

1. Add workout categories and filtering
2. Implement barcode scanning for supplements/food
3. Add custom workout creation form
4. Implement search history and favorites
5. Add animations for a more polished experience 