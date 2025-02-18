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
                    ScrollView {
                        VStack(spacing: 0) {
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
                                .padding(.top, 60)
                            } else {
                                ForEach(workouts) { workout in
                                    WorkoutRow(
                                        exercise: workout.exercise,
                                        weight: workout.weight.map { 
                                            let weightValue = $0
                                            return weightValue.truncatingRemainder(dividingBy: 1) == 0 
                                                ? String(format: "%.0f", weightValue) 
                                                : String(weightValue)
                                        } ?? "-",
                                        sets: workout.sets.map { "\($0)" } ?? "-",
                                        reps: workout.reps.map { "\($0)" } ?? "-",
                                        notes: workout.notes ?? "",
                                        exerciseWidth: exerciseWidth,
                                        weightWidth: weightWidth,
                                        setsWidth: setsWidth,
                                        repsWidth: repsWidth,
                                        notesWidth: notesWidth
                                    )
                                    
                                    if workout.id != workouts.last?.id {
                                        Divider()
                                            .background(Color.gymtimeTextSecondary.opacity(0.2))
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 80) // Reduced padding, still enough for button + nav bar
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

struct WorkoutRow: View {
    let exercise: String
    let weight: String
    let sets: String
    let reps: String
    let notes: String
    
    let exerciseWidth: CGFloat
    let weightWidth: CGFloat
    let setsWidth: CGFloat
    let repsWidth: CGFloat
    let notesWidth: CGFloat
    
    @State private var isExpanded = false
    private let notesThreshold = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 0) {
                Text(exercise)
                    .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
                    .font(.subheadline.weight(.medium))
                Text(weight)
                    .frame(width: UIScreen.main.bounds.width * weightWidth, alignment: .center)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(weight == "-" ? .gymtimeTextSecondary : .gymtimeText)
                Text(sets)
                    .frame(width: UIScreen.main.bounds.width * setsWidth, alignment: .center)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(sets == "-" ? .gymtimeTextSecondary : .gymtimeText)
                Text(reps)
                    .frame(width: UIScreen.main.bounds.width * repsWidth, alignment: .center)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(reps == "-" ? .gymtimeTextSecondary : .gymtimeText)
                
                // Notes column with expansion
                HStack(spacing: 4) {
                    if notes.count > notesThreshold {
                        Text("\(notes.prefix(notesThreshold))...")
                            .lineLimit(1)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    } else {
                        Text(notes)
                            .lineLimit(1)
                    }
                }
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(.gymtimeTextSecondary)
            }
            .padding(.horizontal, 24)
            .contentShape(Rectangle())  // Make entire row tappable
            .onTapGesture {
                if notes.count > notesThreshold {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }
            .padding(.bottom, isExpanded && notes.count > notesThreshold ? 14 : 0) // Add space only when expanded
            
            // Expanded notes view
            if isExpanded && notes.count > notesThreshold {
                Text(notes)
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
    }
} 