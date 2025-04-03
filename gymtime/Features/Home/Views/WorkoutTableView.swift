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

struct WaveAnimation: ViewModifier {
    let isCompleted: Bool
    @State private var isAnimating = false
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        if isCompleted && isAnimating {
                            // Create a wider, more organic wave effect
                            HStack(spacing: 0) {
                                // Left fade for curved effect
                                LinearGradient(
                                    colors: [
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0),
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.1)
                                
                                // Main wave gradient
                                LinearGradient(
                                    colors: [
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.12),
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.18),
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.5)
                                
                                // Right fade for curved effect
                                LinearGradient(
                                    colors: [
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.12),
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.1)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .blur(radius: 8)  // Reduced blur for less roundness
                            .offset(x: offset)
                            .zIndex(1)
                        }
                    }
                }
            }
            .onChange(of: isCompleted) { _, newValue in
                if newValue {
                    offset = 0
                    isAnimating = true
                    // Slower animation with spring effect
                    withAnimation(.interpolatingSpring(duration: 1.0, bounce: 0.2).delay(0.05)) {
                        offset = -UIScreen.main.bounds.width
                    }
                }
            }
    }
}

extension View {
    func waveAnimation(isCompleted: Bool) -> some View {
        modifier(WaveAnimation(isCompleted: isCompleted))
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
    
    // Add keyboard state tracking
    @State private var keyboardHeight: CGFloat = 0
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.26  // Increased for longer exercise names
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let repsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let notesWidth: CGFloat = 0.15     // Further reduced for more table padding
    private let checkmarkWidth: CGFloat = 0.13  // Increased for larger checkmark
    
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
                        // Add empty space for checkmark column to maintain alignment
                        Text("")
                            .frame(width: UIScreen.main.bounds.width * checkmarkWidth)
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
                                            checkmarkWidth: checkmarkWidth,
                                            viewModel: viewModel,
                                            isAnyFieldEditing: $isAnyFieldEditing
                                        )
                                        .id(workout.id.uuidString)  // Convert UUID to String
                                        .background(Color.gymtimeBackground)
                                        .contextMenu {
                                            Button(action: {
                                                viewModel.selectedExerciseForHistory = .init(name: workout.exercise)
                                            }) {
                                                Label("Exercise History", systemImage: "chart.line.uptrend.xyaxis")
                                            }
                                            
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
                                        .sheet(item: $viewModel.selectedExerciseForHistory) { item in
                                            NavigationView {
                                                ExerciseHistoryView(
                                                    exerciseName: item.name,
                                                    onWorkoutTapped: { date in
                                                        viewModel.selectedExerciseForHistory = nil // Dismiss the sheet
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                            viewModel.selectDate(date) // Switch to the selected date
                                                        }
                                                    }
                                                )
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
                        Button(action: {
                            viewModel.toggleRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.gymtimeAccent.opacity(0.3), lineWidth: 2)
                                    )
                                Image(systemName: viewModel.isRecording ? "stop.circle" : "mic")
                                    .font(.system(size: 25, weight: .semibold))
                                    .foregroundColor(.gymtimeAccent)
                            }
                            .shadow(radius: 3, x: 0, y: 1)
                        }
                        .disabled(viewModel.isProcessing)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .padding(.leading, 31)

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
            
            // PB Celebration Modal
            if let pbInfo = viewModel.newPbInfo {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                PBCelebrationView(pbInfo: pbInfo) {
                    withAnimation {
                        viewModel.newPbInfo = nil
                    }
                }
                .transition(.scale.combined(with: .opacity))
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
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.newPbInfo != nil)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            print("⌨️ Keyboard will show")
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                print("   Frame: \(keyboardFrame)")
                keyboardHeight = keyboardFrame.height
            }
            if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                print("   Animation duration: \(duration)")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            print("⌨️ Keyboard will hide")
            keyboardHeight = 0
            if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                print("   Animation duration: \(duration)")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidChangeFrameNotification,
            object: nil,
            queue: .main
        ) { notification in
            print("⌨️ Keyboard frame changed")
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                print("   New frame: \(keyboardFrame)")
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
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
    let textColor: Color?
    let onNavigate: ((FieldType) -> Void)?
    
    @State private var isEditing = false {
        didSet {
            print("🔍 EditableCell[\(workoutId)][\(fieldType)] - isEditing changed: \(oldValue) -> \(isEditing)")
            print("   Current time: \(Date())")
        }
    }
    @State private var editValue: String
    @FocusState private var isFocused: Bool {
        didSet {
            print("🔍 EditableCell[\(workoutId)][\(fieldType)] - isFocused changed: \(oldValue) -> \(isFocused)")
            print("   Current time: \(Date())")
            print("   isEditing: \(isEditing)")
            print("   isAnyFieldEditing: \(isAnyFieldEditing)")
        }
    }
    
    init(value: String, 
         onChange: @escaping (String) -> Void, 
         isNumeric: Bool = false, 
         scrollProxy: ScrollViewProxy,
         workoutId: String,
         isAnyFieldEditing: Binding<Bool>,
         fieldType: FieldType,
         textColor: Color? = nil,
         onNavigate: ((FieldType) -> Void)? = nil) {
        self.value = value
        self.onChange = onChange
        self.isNumeric = isNumeric
        self.scrollProxy = scrollProxy
        self.workoutId = workoutId
        self._editValue = State(initialValue: value)
        self._isAnyFieldEditing = isAnyFieldEditing
        self.fieldType = fieldType
        self.textColor = textColor
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
                                print("🎯 Toolbar[\(workoutId)][\(fieldType)] - Previous button tapped")
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
                                    .accessibilityIdentifier("toolbar-previous-\(workoutId)-\(fieldType)")
                            }
                            .disabled(fieldType.previous == nil)
                            
                            Spacer()
                            
                            // Next button
                            Button(action: {
                                print("🎯 Toolbar[\(workoutId)][\(fieldType)] - Next button tapped")
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
                                    .accessibilityIdentifier("toolbar-next-\(workoutId)-\(fieldType)")
                            }
                            .disabled(fieldType.next == nil)
                            
                            Spacer()
                            
                            // Done button
                            Button(action: {
                                print("🎯 Toolbar[\(workoutId)][\(fieldType)] - Done button tapped")
                                if editValue != value {
                                    onChange(editValue)
                                }
                                isFocused = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                             to: nil,
                                                             from: nil,
                                                             for: nil)
                            }) {
                                Text("Done")
                                    .accessibilityIdentifier("toolbar-done-\(workoutId)-\(fieldType)")
                            }
                        }
                    }
                    .toolbarRole(.editor)
                    .onAppear { 
                        print("📱 EditableCell[\(workoutId)][\(fieldType)] - TextField appeared")
                        print("   Current time: \(Date())")
                        isFocused = true
                        // Only update isAnyFieldEditing if this is the active field
                        if value != editValue {
                            isAnyFieldEditing = true
                        }
                        withAnimation {
                            scrollProxy.scrollTo(workoutId, anchor: .top)
                        }
                    }
                    .onChange(of: isFocused) { oldValue, focused in
                        print("📱 EditableCell[\(workoutId)][\(fieldType)] - Focus change detected")
                        print("   Old focus: \(oldValue)")
                        print("   New focus: \(focused)")
                        print("   Current time: \(Date())")
                        print("   isEditing: \(isEditing)")
                        print("   isAnyFieldEditing: \(isAnyFieldEditing)")
                        
                        if !focused {
                            print("   📝 Field lost focus - starting cleanup")
                            
                            // 1. First, commit any changes
                            if editValue != value {
                                print("   💾 Value changed, triggering onChange")
                                onChange(editValue)
                            }
                            
                            // 2. Reset editing state immediately
                            print("   🔄 Resetting editing state")
                            isEditing = false
                            
                            // 3. Reset parent editing state on next run loop
                            // Remove the condition since we want to reset state regardless of value change
                            DispatchQueue.main.async {
                                print("   🔄 Resetting parent editing state")
                                isAnyFieldEditing = false
                            }
                            
                            print("   ✅ Cleanup sequence completed")
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
                    .foregroundColor(textColor)
            } else {
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editValue = value == "-" ? "" : value
                        isEditing = true
                    }
                    .foregroundColor(textColor ?? (value == "-" ? .gymtimeTextSecondary : .gymtimeText))
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
    let checkmarkWidth: CGFloat  // Add checkmark width
    
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isAnyFieldEditing: Bool
    @State private var isExpanded = false
    @State private var currentlyFocusedField: FieldType?
    private let notesThreshold = 8
    let isBlankEntry: Bool
    @State private var shouldShowWave = false
    @State private var repsOpacity: CGFloat = 1.0
    @State private var setsOpacity: CGFloat = 1.0
    @State private var weightOpacity: CGFloat = 1.0
    @State private var exerciseOpacity: CGFloat = 1.0
    
    init(workout: WorkoutEntry,
         scrollProxy: ScrollViewProxy,
         exerciseWidth: CGFloat,
         weightWidth: CGFloat,
         setsWidth: CGFloat,
         repsWidth: CGFloat,
         notesWidth: CGFloat,
         checkmarkWidth: CGFloat,  // Add parameter
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
        self.checkmarkWidth = checkmarkWidth  // Initialize
        self.viewModel = viewModel
        self._isAnyFieldEditing = isAnyFieldEditing
        self.isBlankEntry = isBlankEntry
    }
    
    // Function to handle field navigation
    func navigateToField(_ field: FieldType) {
        // Only proceed if we're not already navigating
        guard currentlyFocusedField != field else { return }
        
        currentlyFocusedField = field
        
        // If we're navigating away from notes, close any expanded notes
        if field != .notes && isExpanded {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        }
        
        // Wait for cleanup to complete before focusing new field
        DispatchQueue.main.async {
            // This ensures the previous field has time to cleanup
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
                    textColor: nil,
                    onNavigate: navigateToField
                )
                .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
                .font(.subheadline.weight(.medium))
                .opacity(exerciseOpacity)
                
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
                    textColor: nil,
                    onNavigate: navigateToField
                )
                .frame(width: UIScreen.main.bounds.width * weightWidth, alignment: .center)
                .foregroundColor(.gymtimeText)
                .opacity(weightOpacity)
                
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
                    textColor: nil,
                    onNavigate: navigateToField
                )
                .frame(width: UIScreen.main.bounds.width * setsWidth, alignment: .center)
                .foregroundColor(.gymtimeText)
                .opacity(setsOpacity)
                
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
                    textColor: nil,
                    onNavigate: navigateToField
                )
                .frame(width: UIScreen.main.bounds.width * repsWidth, alignment: .center)
                .foregroundColor(.gymtimeText)
                .opacity(repsOpacity)
                
                // Notes column with expansion
                HStack(spacing: 4) {
                    let notes = workout.notes ?? ""
                    if !isBlankEntry && notes.count > notesThreshold {
                        Text("\(notes.prefix(notesThreshold))...")
                            .lineLimit(1)
                            .opacity(workout.isCompleted ? 0.45 : 1.0)  // Updated opacity
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .opacity(workout.isCompleted ? 0.45 : 1.0)  // Updated opacity
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
                            textColor: nil,
                            onNavigate: navigateToField
                        )
                        .lineLimit(1)
                        .opacity(workout.isCompleted ? 0.45 : 1.0)  // Updated opacity
                    }
                }
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(.gymtimeText)
                .onTapGesture {
                    if !isBlankEntry && (workout.notes?.count ?? 0) > notesThreshold {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                }
                
                // Add checkmark button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.toggleWorkoutCompletion(id: workout.id)
                    }
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    ZStack {
                        // Circle border
                        Circle()
                            .strokeBorder(Color.gymtimeTextSecondary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                        
                        // Always show checkmark, but style it differently based on state
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(workout.isCompleted ? .white : Color.gymtimeTextSecondary.opacity(0.5))
                        
                        // Filled background when completed
                        if workout.isCompleted {
                            Circle()
                                .fill(Color(red: 76/255, green: 175/255, blue: 80/255))  // Material Design Green 500
                                .frame(width: 26, height: 26)
                                .zIndex(-1)
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * checkmarkWidth)
                .opacity(isBlankEntry ? 0 : 1) // Hide checkmark for blank entries
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
                    textColor: nil,
                    onNavigate: navigateToField
                )
                .font(.subheadline)
                .foregroundColor(.gymtimeText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // Ensure the entire row is interactive
        .onChange(of: isAnyFieldEditing) { oldValue, newValue in
            print("🔄 WorkoutRow[\(workout.id)] - isAnyFieldEditing changed:")
            print("   Old value: \(oldValue)")
            print("   New value: \(newValue)")
            print("   Current time: \(Date())")
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            print("🔄 WorkoutRow[\(workout.id)] - isExpanded changed:")
            print("   Old value: \(oldValue)")
            print("   New value: \(newValue)")
            print("   Current time: \(Date())")
        }
        .frame(minHeight: 65) // Add minimum height to ensure consistency
        .waveAnimation(isCompleted: shouldShowWave)
        .onAppear {
            if workout.isCompleted {
                repsOpacity = 0.40
                setsOpacity = 0.40
                weightOpacity = 0.40
                exerciseOpacity = 0.40
            }
        }
        .onChange(of: workout.isCompleted) { _, newValue in
            if newValue {
                shouldShowWave = true
                // Stagger the opacity changes to match wave movement (right to left)
                withAnimation(.easeInOut(duration: 0.2).delay(0.05)) {
                    repsOpacity = 0.40  // First (rightmost)
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.15)) {
                    setsOpacity = 0.40  // Second
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.25)) {
                    weightOpacity = 0.40  // Third
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.35)) {
                    exerciseOpacity = 0.40  // Last (leftmost)
                }
                
                // Reset wave flag after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    shouldShowWave = false
                }
            } else {
                // Reset all opacities when unchecking
                withAnimation(.easeInOut(duration: 0.2)) {
                    repsOpacity = 1.0
                    setsOpacity = 1.0
                    weightOpacity = 1.0
                    exerciseOpacity = 1.0
                }
            }
        }
    }
} 