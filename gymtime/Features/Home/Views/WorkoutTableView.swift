// 📄 Displays workout data in a clean, organized table format

import SwiftUI

// Define field types for navigation
enum FieldType: Int, CaseIterable {
    case exercise = 0
    case weight = 1
    case sets = 2
    case reps = 3
    case notes = 4
    
    var next: FieldType? {
        let allCases = FieldType.allCases
        let nextIndex = self.rawValue + 1
        return nextIndex < allCases.count ? allCases[nextIndex] : nil
    }
    
    var previous: FieldType? {
        let allCases = FieldType.allCases
        let prevIndex = self.rawValue - 1
        return prevIndex >= 0 ? allCases[prevIndex] : nil
    }
}

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
    
    // Add this line
    @Binding var showingAnonymousConversion: Bool
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.26  // Increased for longer exercise names
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let repsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let notesWidth: CGFloat = 0.27     // Reduced to accommodate other columns
    
    init(workouts: Binding<[WorkoutEntry]>, viewModel: HomeViewModel, isEditing: Binding<Bool>, showingAnonymousConversion: Binding<Bool>) {
        self._workouts = workouts
        self.viewModel = viewModel
        self._isEditing = isEditing
        self._showingAnonymousConversion = showingAnonymousConversion
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
                                if workouts.isEmpty {
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
                                    
                                    // Add spacer at bottom to prevent content hiding behind buttons
                                    Color.clear
                                        .frame(height: 180)  // Adjust based on bottom UI height
                                }
                            }
                        }
                        .background(Color.gymtimeBackground)
                        .modifier(BottomFadeModifier(itemCount: workouts.count))
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
                                    // Remove animation
                                    // .animation(.easeIn(duration: 0.1), value: viewModel.transcript)
                                
                                // Waveform
                                WaveformView(audioLevel: viewModel.audioLevel)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                        .transition(.identity) // Use identity transition
                        // Disable any container animations
                        .transaction { transaction in
                            transaction.animation = nil  
                        }
                    }
                    
                    // Plus Button
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Plus button tapped - Opening full screen menu")
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
                        .sheet(isPresented: $showingWorkoutMenu, onDismiss: {
                            viewModel.clearSuggestions()
                        }) {
                            WorkoutMenuView(viewModel: viewModel)
                                .edgesIgnoringSafeArea(.bottom)
                        }
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.gymtimeAccent)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        // Use AnimationDisabled to prevent animation of button contents
                        ZStack {  // Use ZStack to avoid layout shifts
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
                    }
                    .disabled(viewModel.isProcessing)
                    // Explicitly disable animations for this button
                    .transaction { transaction in
                        transaction.animation = nil
                    }
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
                    .transition(.identity)
                    .onTapGesture {
                        viewModel.toggleRecording()
                    }
                    .zIndex(2)  // Topmost layer
            }
        }
        // Disable ALL animations throughout the entire view when recording state changes
        .transaction { transaction in
            if viewModel.isRecording != viewModel.audioRecordingService.isRecording {
                transaction.animation = nil
            }
        }
        .ignoresSafeArea(.keyboard)  // Add this modifier to ignore keyboard adjustments
        .onChange(of: isAnyFieldEditing) { _, newValue in
            isEditing = newValue  // Update parent's editing state
        }
        .sheet(isPresented: $showingAnonymousConversion) {
            AnonymousConversionView(isPresented: $showingAnonymousConversion)
        }
        .onChange(of: showingAnonymousConversion) { oldValue, newValue in
            print("🔄 WorkoutTableView - showingAnonymousConversion changed:")
            print("   - Old value: \(oldValue)")
            print("   - New value: \(newValue)")
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
    let fieldType: FieldType
    let onNavigate: ((FieldType) -> Void)?
    
    @State private var isEditing = false
    @State private var editValue: String
    @FocusState private var isFocused: Bool
    
    init(value: String, 
         onChange: @escaping (String) -> Void, 
         isNumeric: Bool = false, 
         scrollProxy: ScrollViewProxy,
         workoutId: String,
         isAnyFieldEditing: Binding<Bool>,
         fieldType: FieldType,
         onNavigate: ((FieldType) -> Void)? = nil) {
        self.value = value
        self.onChange = onChange
        self.isNumeric = isNumeric
        self.scrollProxy = scrollProxy
        self.workoutId = workoutId
        self._editValue = State(initialValue: value)
        self._isAnyFieldEditing = isAnyFieldEditing
        self.fieldType = fieldType
        self.onNavigate = onNavigate
    }
    
    var body: some View {
        Group {
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
                            // Previous button
                            Button(action: {
                                if let previous = fieldType.previous {
                                    // We need to commit the current value first
                                    if editValue != value {
                                        onChange(editValue)
                                    }
                                    onNavigate?(previous)
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(fieldType.previous != nil ? .gymtimeAccent : .gray)
                            }
                            .disabled(fieldType.previous == nil)
                            
                            Spacer()
                            
                            // Next button
                            Button(action: {
                                if let next = fieldType.next {
                                    // We need to commit the current value first
                                    if editValue != value {
                                        onChange(editValue)
                                    }
                                    onNavigate?(next)
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(fieldType.next != nil ? .gymtimeAccent : .gray)
                            }
                            .disabled(fieldType.next == nil)
                            
                            Spacer()
                            
                            // Done button
                            Button("Done") {
                                if editValue != value {
                                    onChange(editValue)
                                }
                                isFocused = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                             to: nil,
                                                             from: nil,
                                                             for: nil)
                            }
                        }
                    }
                    .toolbarRole(.editor)
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusField"))) { notification in
            if let rowId = notification.userInfo?["rowId"] as? String,
               let fieldTypeRaw = notification.userInfo?["fieldType"] as? Int,
               rowId == workoutId,
               let notificationFieldType = FieldType(rawValue: fieldTypeRaw),
               notificationFieldType == fieldType {
                // This notification is for us - focus this field
                DispatchQueue.main.async {
                    editValue = value == "-" ? "" : value
                    isEditing = true
                }
            }
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
    @State private var currentlyFocusedField: FieldType?
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
    
    // Function to handle field navigation
    func navigateToField(_ field: FieldType) {
        currentlyFocusedField = field
        
        // If we're navigating away from notes, close any expanded notes
        if field != .notes && isExpanded {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        }
        
        // Simulate a tap on the appropriate field to focus it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This ensures the previous field has time to save its value
            // before we focus the new field
            NotificationCenter.default.post(
                name: Notification.Name("FocusField"),
                object: nil,
                userInfo: ["rowId": workout.id.uuidString, "fieldType": field.rawValue]
            )
        }
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
                    isAnyFieldEditing: $isAnyFieldEditing,
                    fieldType: .exercise,
                    onNavigate: navigateToField
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
                    isAnyFieldEditing: $isAnyFieldEditing,
                    fieldType: .weight,
                    onNavigate: navigateToField
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
                    isAnyFieldEditing: $isAnyFieldEditing,
                    fieldType: .sets,
                    onNavigate: navigateToField
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
                    isAnyFieldEditing: $isAnyFieldEditing,
                    fieldType: .reps,
                    onNavigate: navigateToField
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
                            isAnyFieldEditing: $isAnyFieldEditing,
                            fieldType: .notes,
                            onNavigate: navigateToField
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
                    isAnyFieldEditing: $isAnyFieldEditing,
                    fieldType: .notes,
                    onNavigate: navigateToField
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