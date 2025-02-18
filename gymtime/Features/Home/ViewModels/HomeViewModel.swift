// 📄 Manages state and business logic for the home screen

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntry] = []
    @Published var selectedDate: Date = Date()
    
    // Audio recording service
    private let audioRecordingService = AudioRecordingService()
    private let speechRecognitionService = SpeechRecognitionService()
    
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var transcript: String = ""
    @Published var error: String?
    
    init() {
        // Initialize any required state
        loadWorkouts()
        
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
    
    func toggleRecording() {
        if isRecording {
            audioRecordingService.stopRecording()
            speechRecognitionService.stopRecording()
        } else {
            audioRecordingService.startRecording()
            speechRecognitionService.startRecording()
        }
    }
} 