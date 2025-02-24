// 📄 Manages state and business logic for the home screen

import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Data
    @Published var workouts: [WorkoutEntry] = []
    @Published var calendarState: CalendarState
    
    // UI State - Voice Recording
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var transcript: String = ""
    
    // UI State - Workout Summary
    @Published var aiWorkoutSummary: String = ""
    @Published var isLoadingSummary: Bool = false
    
    // UI State - Suggestions
    @Published var isSuggestionsVisible: Bool = false
    @Published var suggestedWorkouts: [WorkoutEntry] = []
    @Published var blankWorkoutEntry: WorkoutEntry?
    
    // Error Handling
    @Published var error: String?
    
    // MARK: - Services
    
    let audioRecordingService = AudioRecordingService()
    let speechRecognitionService = SpeechRecognitionService()
    let workoutParser: WorkoutParser
    
    // MARK: - Private Properties
    
    var summaryCache: [Date: String] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Initialize calendar state
        self.calendarState = CalendarState()
        
        // Initialize services
        let openAIService = OpenAIService(apiKey: Config.openAIApiKey)
        self.workoutParser = WorkoutParser(openAIService: openAIService, supabase: supabase)
        
        // Initialize state
        loadWorkouts()
        
        // Set up service observations
        setupServiceObservers()
        
        // Set up date change observer
        setupDateChangeObserver()
    }
    
    private func setupServiceObservers() {
        audioRecordingService.$audioLevel
            .assign(to: &$audioLevel)
        
        audioRecordingService.$isRecording
            .assign(to: &$isRecording)
            
        speechRecognitionService.$transcript
            .assign(to: &$transcript)
            
        speechRecognitionService.$error
            .assign(to: &$error)
    }
    
    private func setupDateChangeObserver() {
        // Observe changes to the selected date
        $calendarState
            .map { $0.selectedDate }
            .removeDuplicates { Calendar.current.isDate($0, inSameDayAs: $1) }
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                // Hide suggestions when date changes
                withAnimation {
                    self?.isSuggestionsVisible = false
                    self?.suggestedWorkouts = []
                    self?.blankWorkoutEntry = nil
                }
            }
            .store(in: &cancellables)
    }
}