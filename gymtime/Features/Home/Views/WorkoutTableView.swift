// 📄 Displays workout data in a clean, organized table format

import SwiftUI

struct WorkoutTableView: View {
    @Binding var workouts: [WorkoutEntry]
    @ObservedObject var viewModel: HomeViewModel
    
    // Column widths (proportional)
    private let exerciseWidth: CGFloat = 0.3  // Increased since we removed date
    private let weightWidth: CGFloat = 0.15
    private let setsWidth: CGFloat = 0.1
    private let repsWidth: CGFloat = 0.1
    private let notesWidth: CGFloat = 0.35    // Increased for better note visibility
    
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
                            .frame(width: UIScreen.main.bounds.width * weightWidth)
                        Text("SETS")
                            .frame(width: UIScreen.main.bounds.width * setsWidth)
                        Text("REPS")
                            .frame(width: UIScreen.main.bounds.width * repsWidth)
                        Text("NOTES")
                            .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gymtimeTextSecondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.3))
                    
                    // Table Content
                    ScrollView {
                        VStack(spacing: 0) {
                            if workouts.isEmpty {
                                Text("No workouts recorded yet")
                                    .foregroundColor(.gymtimeTextSecondary)
                                    .padding(.top, 40)
                            } else {
                                ForEach(workouts) { workout in
                                    WorkoutRow(
                                        exercise: workout.exercise,
                                        weight: workout.weight.map { "\($0) lb" } ?? "-",
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
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100) // Increased padding to account for button + nav bar
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
                .padding(.bottom, 65)
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
    
    var body: some View {
        HStack(spacing: 0) {
            Text(exercise)
                .frame(width: UIScreen.main.bounds.width * exerciseWidth, alignment: .leading)
            Text(weight)
                .frame(width: UIScreen.main.bounds.width * weightWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(sets)
                .frame(width: UIScreen.main.bounds.width * setsWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(reps)
                .frame(width: UIScreen.main.bounds.width * repsWidth)
                .font(.system(.subheadline, design: .monospaced))
            Text(notes)
                .frame(width: UIScreen.main.bounds.width * notesWidth, alignment: .leading)
        }
        .foregroundColor(.gymtimeText)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)  // Updated to match header padding
    }
} 