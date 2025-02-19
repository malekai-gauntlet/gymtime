// 📄 Displays workout data in a clean, organized table format

import SwiftUI

struct WorkoutTableView: View {
    @Binding var workouts: [WorkoutEntry]
    @ObservedObject var viewModel: HomeViewModel
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.26  // Increased for longer exercise names
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let repsWidth: CGFloat = 0.13      // Slightly increased for better spacing
    private let notesWidth: CGFloat = 0.27     // Reduced to accommodate other columns
    
    var body: some View {
        ZStack {
            // Main Content
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
                    List {
                        if workouts.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gymtimeTextSecondary)
                                Text("No workouts recorded yet")
                                    .font(.headline)
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 60)
                            .listRowBackground(Color.gymtimeBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        } else {
                            ForEach(workouts) { workout in
                                WorkoutRow(
                                    workout: workout,
                                    exerciseWidth: exerciseWidth,
                                    weightWidth: weightWidth,
                                    setsWidth: setsWidth,
                                    repsWidth: repsWidth,
                                    notesWidth: notesWidth,
                                    viewModel: viewModel
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.gymtimeBackground)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        print("🔴 Delete button tapped for workout: \(workout.id)")
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            viewModel.deleteWorkout(id: workout.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "minus.circle")
                                    }
                                    .tint(.red)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.gymtimeBackground)
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
                            // TODO: Add new workout action
                            print("Plus button tapped")
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
                .zIndex(1)
            }
            
            // Dimming Overlay
            if viewModel.isRecording {
                Color.black
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        viewModel.toggleRecording()
                    }
                    .zIndex(0)  // Between main content and recording UI
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
    }
}

struct EditableCell: View {
    let value: String
    let onChange: (String) -> Void
    let alignment: TextAlignment
    let isNumeric: Bool
    
    @State private var isEditing = false
    @State private var editValue: String
    @FocusState private var isFocused: Bool
    
    init(value: String, onChange: @escaping (String) -> Void, alignment: TextAlignment = .leading, isNumeric: Bool = false) {
        self.value = value
        self.onChange = onChange
        self.alignment = alignment
        self.isNumeric = isNumeric
        self._editValue = State(initialValue: value)
    }
    
    var body: some View {
        if isEditing {
            TextField("", text: $editValue)
                .multilineTextAlignment(alignment)
                .keyboardType(isNumeric ? .numberPad : .default)
                .font(.system(.subheadline, design: isNumeric ? .monospaced : .default))
                .focused($isFocused)
                .onChange(of: isFocused) { focused in
                    if !focused {
                        isEditing = false
                        if editValue != value {
                            onChange(editValue)
                        }
                    }
                }
                .onTapGesture {}  // Prevents tap from dismissing keyboard
        } else {
            Text(value)
                .onTapGesture {
                    editValue = value
                    isEditing = true
                    isFocused = true
                }
        }
    }
}

struct WorkoutRow: View {
    let workout: WorkoutEntry
    
    let exerciseWidth: CGFloat
    let weightWidth: CGFloat
    let setsWidth: CGFloat
    let repsWidth: CGFloat
    let notesWidth: CGFloat
    
    @ObservedObject var viewModel: HomeViewModel
    @State private var isExpanded = false
    private let notesThreshold = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 0) {
                EditableCell(
                    value: workout.exercise,
                    onChange: { viewModel.updateWorkout(id: workout.id, field: "exercise", value: $0) }
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
                    onChange: { viewModel.updateWorkout(id: workout.id, field: "weight", value: $0) },
                    alignment: .center,
                    isNumeric: true
                )
                .frame(width: UIScreen.main.bounds.width * weightWidth, alignment: .center)
                .foregroundColor(workout.weight == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                EditableCell(
                    value: workout.sets.map { "\($0)" } ?? "-",
                    onChange: { viewModel.updateWorkout(id: workout.id, field: "sets", value: $0) },
                    alignment: .center,
                    isNumeric: true
                )
                .frame(width: UIScreen.main.bounds.width * setsWidth, alignment: .center)
                .foregroundColor(workout.sets == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                EditableCell(
                    value: workout.reps.map { "\($0)" } ?? "-",
                    onChange: { viewModel.updateWorkout(id: workout.id, field: "reps", value: $0) },
                    alignment: .center,
                    isNumeric: true
                )
                .frame(width: UIScreen.main.bounds.width * repsWidth, alignment: .center)
                .foregroundColor(workout.reps == nil ? .gymtimeTextSecondary : .gymtimeText)
                
                // Notes column with expansion
                HStack(spacing: 4) {
                    let notes = workout.notes ?? ""
                    if notes.count > notesThreshold {
                        Text("\(notes.prefix(notesThreshold))...")
                            .lineLimit(1)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    } else {
                        EditableCell(
                            value: notes,
                            onChange: { viewModel.updateWorkout(id: workout.id, field: "notes", value: $0) }
                        )
                        .lineLimit(1)
                    }
                }
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(.gymtimeTextSecondary)
            }
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
            .onTapGesture {
                print("👆 Tap detected on workout row: \(workout.id)")
                if (workout.notes?.count ?? 0) > notesThreshold {
                    print("📝 Notes expansion triggered")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                        print("📖 Notes expanded state: \(isExpanded)")
                    }
                }
            }
            .padding(.bottom, isExpanded && (workout.notes?.count ?? 0) > notesThreshold ? 14 : 0)
            
            // Expanded notes view
            if isExpanded && (workout.notes?.count ?? 0) > notesThreshold {
                EditableCell(
                    value: workout.notes ?? "",
                    onChange: { viewModel.updateWorkout(id: workout.id, field: "notes", value: $0) }
                )
                .font(.subheadline)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .foregroundColor(.gymtimeText)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // Ensure the entire row is interactive
        .onAppear {
            print("🎯 WorkoutRow appeared for workout: \(workout.id)")
            print("📊 Initial layout - Width parameters:")
            print("  Exercise: \(exerciseWidth)")
            print("  Weight: \(weightWidth)")
            print("  Sets: \(setsWidth)")
            print("  Reps: \(repsWidth)")
            print("  Notes: \(notesWidth)")
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            print("🔄 Expansion state changed for workout \(workout.id): \(oldValue) -> \(newValue)")
        }
    }
} 