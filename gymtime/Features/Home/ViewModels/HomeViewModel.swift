// 📄 Manages state and business logic for the home screen

import Foundation
import SwiftUI


@MainActor
class HomeViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntry] = []
    @Published var selectedDate: Date = Date()
    
    // Services
    private let audioRecordingService = AudioRecordingService()
    private let speechRecognitionService = SpeechRecognitionService()
    private let workoutParser: WorkoutParser
    
    // UI State
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var transcript: String = ""
    @Published var error: String?
    
    init() {
        // Initialize services
        let openAIService = OpenAIService(apiKey: Config.openAIApiKey)
        self.workoutParser = WorkoutParser(openAIService: openAIService)
        
        // Initialize state
        loadWorkouts()
        
        // Add sample workout for development
        #if DEBUG
        self.workouts.append(
            WorkoutEntry(
                id: UUID(),
                exercise: "Bench Press",
                weight: 185.0,
                sets: 3,
                reps: 5,
                notes: "Feeling strong today! This is a longer note to test the expansion feature."
            )
        )
        #endif
        
        // Set up audio level observation
        audioRecordingService.$audioLevel
            .assign(to: &$audioLevel)
        
        audioRecordingService.$isRecording
            .assign(to: &$isRecording)
            
        // Set up speech recognition observation
        speechRecognitionService.$transcript
            .assign(to: &$transcript)
            
        speechRecognitionService.$error
            .assign(to: &$error)
    }
    
    func loadWorkouts() {
        // TODO: Implement workout loading from persistence
    }
    
    func addWorkout(_ workout: WorkoutEntry) {
        workouts.insert(workout, at: 0)
        // TODO: Implement persistence
    }
    
    func updateWorkout(id: UUID, field: String, value: String) {
        // Update local state immediately for responsive UI
        if let index = workouts.firstIndex(where: { $0.id == id }) {
            var workout = workouts[index]
            
            // Update the appropriate field
            switch field {
            case "exercise":
                workout.exercise = value
            case "weight":
                workout.weight = Double(value)
            case "sets":
                workout.sets = Int(value)
            case "reps":
                workout.reps = Int(value)
            case "notes":
                workout.notes = value
            default:
                break
            }
            
            // Update in array
            workouts[index] = workout
            
            // TODO: Implement persistence update
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        transcript = ""
        error = nil
        audioRecordingService.startRecording()
        speechRecognitionService.startRecording()
    }
    
    private func stopRecording() {
        audioRecordingService.stopRecording()
        speechRecognitionService.stopRecording()
        
        // Only process if we have a transcript
        guard !transcript.isEmpty else { return }
        
        Task {
            isProcessing = true
            do {
                let workouts = try await workoutParser.parse(text: transcript)
                // Add workouts in reverse order so they appear in the order they were spoken
                for workout in workouts.reversed() {
                    addWorkout(workout)
                }
            } catch {
                self.error = "Failed to process workout: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }
} 