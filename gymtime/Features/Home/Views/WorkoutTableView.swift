// 📄 Displays workout data in a clean, organized table format

import SwiftUI

// Custom view modifier for bottom fade effect
struct BottomFadeModifier: ViewModifier {
    let itemCount: Int
    
    func body(content: Content) -> some View {
        content
            .mask(
                VStack(spacing: 0) {
                    // Main content area - fully visible
                    Rectangle()
                        .fill(Color.white)
                    
                    // Gradient fade out at bottom
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.3),  // Start fading at 30% from top
                            .init(color: .clear, location: 0.9)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 230)  // Increased height to start fade higher
                }
            )
    }
}

struct WorkoutTableView: View {
    @Binding var workouts: [WorkoutEntry]
    @ObservedObject var viewModel: HomeViewModel
    @State private var isAnyFieldEditing = false
    @Binding var isEditing: Bool  // Add binding for parent view
    
    // Add state for showing the workout menu
    @State private var showingWorkoutMenu = false
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.26  // Increased for longer exercise names
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let repsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let notesWidth: CGFloat = 0.27     // Reduced to accommodate other columns
    
    init(workouts: Binding<[WorkoutEntry]>, viewModel: HomeViewModel, isEditing: Binding<Bool>) {
        self._workouts = workouts
        self.viewModel = viewModel
        self._isEditing = isEditing
    }
    
    var body: some View {
        ZStack {
            // Base Layer: Main Content
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 0) {
                        Text("EXERCISE")
                            .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
                        Text("WEIGHT")
                            .frame(width: UIScreen.main.bounds.width * weightWidth, alignment: .center)
                        Text("SETS")
                            .frame(width: UIScreen.main.bounds.width * setsWidth, alignment: .center)
                        Text("REPS")
                            .frame(width: UIScreen.main.bounds.width * repsWidth, alignment: .center)
                        Text("NOTES")
                            .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                    }
                    .font(.system(size: 13, weight: .semibold))  // Slightly larger header text
                    .foregroundColor(.gymtimeTextSecondary)
                    .padding(.vertical, 14)                       // Increased vertical padding
                    .padding(.horizontal, 24)                     // Increased horizontal padding
                    .background(Color.black.opacity(0.3))
                    
                    // Table Content
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if workouts.isEmpty /* && viewModel.suggestedWorkouts.isEmpty */ {
                                    VStack(spacing: 8) {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gymtimeTextSecondary)
                                        Text("No workouts recorded yet")
                                            .font(.headline)
                                            .foregroundColor(.gymtimeTextSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300) // Fixed height when empty
                                    .background(Color.gymtimeBackground)
                                    .padding(.horizontal, 0)
                                } else {
                                    // Regular workouts
                                    ForEach(workouts) { workout in
                                        WorkoutRow(
                                            workout: workout,
                                            scrollProxy: proxy,
                                            exerciseWidth: exerciseWidth,
                                            weightWidth: weightWidth,
                                            setsWidth: setsWidth,
                                            repsWidth: repsWidth,
                                            notesWidth: notesWidth,
                                            viewModel: viewModel,
                                            isAnyFieldEditing: $isAnyFieldEditing
                                        )
                                        .id(workout.id.uuidString)  // Convert UUID to String
                                        .background(Color.gymtimeBackground)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                print("🔴 Delete button tapped for workout: \(workout.id)")
                                                
                                                // Use a faster animation for more responsive feel
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    // Just call deleteWorkout and let it handle both local and remote deletion
                                                    viewModel.deleteWorkout(id: workout.id)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    }
                                    
                                    // Suggested workouts
                                    /* Comment out the entire suggestions section
                                    ForEach(viewModel.suggestedWorkouts) { suggestion in
                                        WorkoutRow(
                                            workout: suggestion,
                                            scrollProxy: proxy,
                                            exerciseWidth: exerciseWidth,
                                            weightWidth: weightWidth,
                                            setsWidth: setsWidth,
                                            repsWidth: repsWidth,
                                            notesWidth: notesWidth,
                                            viewModel: viewModel,
                                            isAnyFieldEditing: $isAnyFieldEditing
                                        )
                                        .background(Color.gymtimeBackground)
                                        .opacity(0.4)
                                        .overlay(
                                            Button(action: {
                                                
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    viewModel.addSuggestionToWorkouts(suggestion)
                                                }
                                            }) {
                                                ZStack {
                                                    // Invisible larger tap area
                                                    Color.clear
                                                        .frame(width: 60, height: 60)
                                                        .onTapGesture {
                                                            print("🎯 Tap area hit for \(suggestion.exercise)")
                                                        }
                                                    
                                                    // Visual checkmark remains the same size
                                                    Image(systemName: "checkmark.circle")
                                                        .foregroundColor(.gymtimeAccent)
                                                        .font(.system(size: 24))
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onAppear {
                                                print("🔲 Suggestion button appeared: \(suggestion.exercise)")
                                            }
                                            .padding(.trailing, 24),
                                            alignment: .trailing
                                        )
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .onAppear {
                                            print("📍 Suggestion row appeared: \(suggestion.exercise)")
                                        }
                                    }
                                    */
                                    
                                    // Add blank workout entry if available
                                    /* Comment out blank workout entry
                                    if let blankWorkout = viewModel.blankWorkoutEntry {
                                        WorkoutRow(
                                            workout: blankWorkout,
                                            scrollProxy: proxy,
                                            exerciseWidth: exerciseWidth,
                                            weightWidth: weightWidth,
                                            setsWidth: setsWidth,
                                            repsWidth: repsWidth,
                                            notesWidth: notesWidth,
                                            viewModel: viewModel,
                                            isAnyFieldEditing: $isAnyFieldEditing,
                                            isBlankEntry: true
                                        )
                                        .background(Color.gymtimeBackground)
                                        .opacity(0.4)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                    */
                                    
                                    // Add spacer at bottom to prevent content hiding behind buttons
                                    Color.clear
                                        .frame(height: 180)  // Adjust based on bottom UI height
                                }
                            }
                        }
                        .background(Color.gymtimeBackground)
                        .modifier(BottomFadeModifier(itemCount: workouts.count /* + (viewModel.blankWorkoutEntry != nil ? 1 : 0) */ /* + viewModel.suggestedWorkouts.count */))
                    }
                }
                .background(Color.gymtimeBackground)
                
                // Record Workout Button and Recording UI
                VStack(spacing: 16) {
                    if viewModel.isRecording || viewModel.isProcessing {
                        // Recording UI Container
                        VStack(spacing: 12) {
                            if viewModel.isProcessing {
                                // Processing indicator
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .accentColor(.gymtimeAccent)
                                    Text("Processing workout...")
                                        .font(.subheadline)
                                        .foregroundColor(.gymtimeText)
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .padding(.vertical)
                            } else {
                                // Transcript area with minimum height
                                Text(viewModel.transcript)
                                    .font(.subheadline)
                                    .foregroundColor(.gymtimeText)
                                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .opacity(viewModel.transcript.isEmpty ? 0 : 1)
                                    .animation(.easeIn(duration: 0.1), value: viewModel.transcript)
                                
                                // Waveform
                                WaveformView(audioLevel: viewModel.audioLevel)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                    }
                    
                    // Plus Button
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Plus button tapped - Opening full screen menu")
                            showingWorkoutMenu = true
                            // Commented out previous functionality - will be replaced with full-screen menu
                            // viewModel.toggleSuggestions()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.gymtimeAccent.opacity(0.3), lineWidth: 2)
                                    )
                                // Always show plus icon now, regardless of suggestions state
                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.gymtimeAccent)
                            }
                            .shadow(radius: 3, x: 0, y: 1)
                        }
                        .padding(.trailing, 31)
                        .sheet(isPresented: $showingWorkoutMenu, onDismiss: {
                            // Clear suggestions when the menu is dismissed
                            viewModel.clearSuggestions()
                        }) {
                            WorkoutMenuView(viewModel: viewModel)
                                .edgesIgnoringSafeArea(.bottom)
                        }
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 20))
                            Text(viewModel.isRecording ? "Stop Recording" : "Record Workout")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .padding(.vertical, 16)
                        .background(viewModel.isRecording ? Color.red : Color.gymtimeAccent)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isProcessing)
                }
                .padding(.bottom, 25)
            }
            .zIndex(0)  // Base layer
            
            // Middle Layer: Editing Overlay
            if isAnyFieldEditing {
                Color.clear
                    .opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())  // Ensure entire area is tappable
                    .onTapGesture { location in
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        let window = windowScene?.windows.first
                        let bounds = window?.bounds ?? .zero
                        
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                     to: nil,
                                                     from: nil,
                                                     for: nil)
                        
                        // Log after attempting to resign
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Empty closure body - this is fine
                        }
                    }
                    .zIndex(1)
            }
            
            // Top Layer: Recording Overlay
            if viewModel.isRecording {
                Color.black
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        viewModel.toggleRecording()
                    }
                    .zIndex(2)  // Topmost layer
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
        .ignoresSafeArea(.keyboard)  // Add this modifier to ignore keyboard adjustments
        .onChange(of: isAnyFieldEditing) { _, newValue in
            isEditing = newValue  // Update parent's editing state
        }
    }
}

struct EditableCell: View {
    let value: String
    let onChange: (String) -> Void
    let isNumeric: Bool
    let scrollProxy: ScrollViewProxy
    let workoutId: String
    @Binding var isAnyFieldEditing: Bool
    
    @State private var isEditing = false
    @State private var editValue: String
    @FocusState private var isFocused: Bool
    
    init(value: String, 
         onChange: @escaping (String) -> Void, 
         isNumeric: Bool = false, 
         scrollProxy: ScrollViewProxy,
         workoutId: String,
         isAnyFieldEditing: Binding<Bool>) {
        self.value = value
        self.onChange = onChange
        self.isNumeric = isNumeric
        self.scrollProxy = scrollProxy
        self.workoutId = workoutId
        self._editValue = State(initialValue: value)
        self._isAnyFieldEditing = isAnyFieldEditing
    }
    
    var body: some View {
        if isEditing {
            TextField("", text: $editValue)
                .keyboardType(isNumeric ? .numberPad : .default)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(4)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                         to: nil,
                                                         from: nil,
                                                         for: nil)
                        }
                    }
                }
                .onAppear { 
                    isFocused = true
                    isAnyFieldEditing = true
                    withAnimation {
                        scrollProxy.scrollTo(workoutId, anchor: .top)
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        if editValue != value {
                            onChange(editValue)
                        }
                        // Ensure state is fully reset after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isEditing = false
                            isAnyFieldEditing = false
                        }
                    }
                }
                .onSubmit {
                    if editValue != value {
                        onChange(editValue)
                    }
                    // Force keyboard dismissal
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                 to: nil,
                                                 from: nil,
                                                 for: nil)
                    isFocused = false
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gymtimeAccent, lineWidth: 1)
                )
        } else {
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    editValue = value == "-" ? "" : value
                    isEditing = true
                }
                .foregroundColor(value == "-" ? .gymtimeTextSecondary : .gymtimeText)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gymtimeAccent.opacity(0.2), lineWidth: 1)
                        .opacity(0)
                        .opacity(isEditing ? 1 : 0)
                )
        }
    }
}

struct WorkoutRow: View {
    let workout: WorkoutEntry
    let scrollProxy: ScrollViewProxy
    
    let exerciseWidth: CGFloat
    let weightWidth: CGFloat
    let setsWidth: CGFloat
    let repsWidth: CGFloat
    let notesWidth: CGFloat
    
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isAnyFieldEditing: Bool
    @State private var isExpanded = false
    private let notesThreshold = 8
    let isBlankEntry: Bool
    
    init(workout: WorkoutEntry,
         scrollProxy: ScrollViewProxy,
         exerciseWidth: CGFloat,
         weightWidth: CGFloat,
         setsWidth: CGFloat,
         repsWidth: CGFloat,
         notesWidth: CGFloat,
         viewModel: HomeViewModel,
         isAnyFieldEditing: Binding<Bool>,
         isBlankEntry: Bool = false) {
        self.workout = workout
        self.scrollProxy = scrollProxy
        self.exerciseWidth = exerciseWidth
        self.weightWidth = weightWidth
        self.setsWidth = setsWidth
        self.repsWidth = repsWidth
        self.notesWidth = notesWidth
        self.viewModel = viewModel
        self._isAnyFieldEditing = isAnyFieldEditing
        self.isBlankEntry = isBlankEntry
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 0) {
                EditableCell(
                    value: workout.exercise,
                    onChange: { value in
                        if isBlankEntry {
                            viewModel.updateBlankWorkoutField(field: "exercise", value: value)
                        } else {
                            viewModel.updateWorkoutField(id: workout.id, field: "exercise", value: value)
                        }
                    },
                    isNumeric: false,
                    scrollProxy: scrollProxy,
                    workoutId: workout.id.uuidString,
                    isAnyFieldEditing: $isAnyFieldEditing
                )
                .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
                .font(.subheadline.weight(.medium))
                
                EditableCell(
                    value: workout.weight.map { 
                        let weightValue = $0
                        return weightValue.truncatingRemainder(dividingBy: 1) == 0 
                            ? String(format: "%.0f", weightValue) 
                            : String(weightValue)
                    } ?? "-",
                    onChange: { value in
                        if isBlankEntry {
                            viewModel.updateBlankWorkoutField(field: "weight", value: value)
                        } else {
                            viewModel.updateWorkoutField(id: workout.id, field: "weight", value: value)
                        }
                    },
                    isNumeric: true,
                    scrollProxy: scrollProxy,
                    workoutId: workout.id.uuidString,
                    isAnyFieldEditing: $isAnyFieldEditing
                )
                .frame(width: UIScreen.main.bounds.width * weightWidth, alignment: .center)
                .foregroundColor(workout.weight == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                EditableCell(
                    value: workout.sets.map { "\($0)" } ?? "-",
                    onChange: { value in
                        if isBlankEntry {
                            viewModel.updateBlankWorkoutField(field: "sets", value: value)
                        } else {
                            viewModel.updateWorkoutField(id: workout.id, field: "sets", value: value)
                        }
                    },
                    isNumeric: true,
                    scrollProxy: scrollProxy,
                    workoutId: workout.id.uuidString,
                    isAnyFieldEditing: $isAnyFieldEditing
                )
                .frame(width: UIScreen.main.bounds.width * setsWidth, alignment: .center)
                .foregroundColor(workout.sets == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                EditableCell(
                    value: workout.reps.map { "\($0)" } ?? "-",
                    onChange: { value in
                        if isBlankEntry {
                            viewModel.updateBlankWorkoutField(field: "reps", value: value)
                        } else {
                            viewModel.updateWorkoutField(id: workout.id, field: "reps", value: value)
                        }
                    },
                    isNumeric: true,
                    scrollProxy: scrollProxy,
                    workoutId: workout.id.uuidString,
                    isAnyFieldEditing: $isAnyFieldEditing
                )
                .frame(width: UIScreen.main.bounds.width * repsWidth, alignment: .center)
                .foregroundColor(workout.reps == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                // Notes column with expansion
                HStack(spacing: 4) {
                    let notes = workout.notes ?? ""
                    if !isBlankEntry && notes.count > notesThreshold {
                        Text("\(notes.prefix(notesThreshold))...")
                            .lineLimit(1)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    } else {
                        EditableCell(
                            value: notes,
                            onChange: { value in
                                if isBlankEntry {
                                    viewModel.updateBlankWorkoutField(field: "notes", value: value)
                                } else {
                                    viewModel.updateWorkoutField(id: workout.id, field: "notes", value: value)
                                }
                            },
                            isNumeric: false,
                            scrollProxy: scrollProxy,
                            workoutId: workout.id.uuidString,
                            isAnyFieldEditing: $isAnyFieldEditing
                        )
                        .lineLimit(1)
                    }
                }
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(.gymtimeTextSecondary)
                .onTapGesture {
                    if !isBlankEntry && (workout.notes?.count ?? 0) > notesThreshold {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, isExpanded && (workout.notes?.count ?? 0) > notesThreshold ? 14 : 0)  // Add dynamic padding
            
            // Expanded notes view
            if isExpanded && (workout.notes?.count ?? 0) > notesThreshold {
                EditableCell(
                    value: workout.notes ?? "",
                    onChange: { value in
                        viewModel.updateWorkoutField(id: workout.id, field: "notes", value: value)
                    },
                    isNumeric: false,
                    scrollProxy: scrollProxy,
                    workoutId: workout.id.uuidString,
                    isAnyFieldEditing: $isAnyFieldEditing
                )
                .font(.subheadline)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // Ensure the entire row is interactive
        .onChange(of: isExpanded) { oldValue, newValue in
            print("🔄 Expansion state changed for workout \(workout.id): \(oldValue) -> \(newValue)")
        }
    }
} 