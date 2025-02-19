// 📄 Manages state and business logic for the home screen

import Foundation
import SwiftUI
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntry] = []
    @Published var calendarState: CalendarState
    
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
        // Initialize calendar state
        self.calendarState = CalendarState()
        
        // Initialize services
        let openAIService = OpenAIService(apiKey: Config.openAIApiKey)
        self.workoutParser = WorkoutParser(openAIService: openAIService, supabase: supabase)
        
        // Initialize state
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
    
    // MARK: - Calendar Management
    
    func selectDate(_ date: Date) {
        calendarState.selectDate(date)
        // TODO: Filter workouts for selected date once persistence is implemented
    }
    
    func moveToDate(_ date: Date) {
        calendarState.moveToDate(date)
    }
    
    func moveToNextWeek() {
        calendarState.moveToNextWeek()
    }
    
    func moveToPreviousWeek() {
        calendarState.moveToPreviousWeek()
    }
    
    func moveToNextMonth() {
        calendarState.moveToNextMonth()
    }
    
    func moveToPreviousMonth() {
        calendarState.moveToPreviousMonth()
    }
    
    // MARK: - Workout Management
    
    func loadWorkouts() {
        Task {
            do {
                let response: [WorkoutEntry] = try await supabase.database
                    .from("workouts")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    self.workouts = response
                }
            } catch {
                print("Error loading workouts: \(error)")
                self.error = "Failed to load workouts"
            }
        }
    }
    
    func addWorkout(_ workout: WorkoutEntry) {
        Task {
            do {
                try await supabase.database
                    .from("workouts")
                    .insert(workout)
                    .execute()
                
                // Add to local state after successful save
                DispatchQueue.main.async {
                    self.workouts.insert(workout, at: 0)
                }
            } catch {
                print("Error saving workout: \(error)")
                self.error = "Failed to save workout"
            }
        }
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
    
    func deleteWorkout(id: UUID) {
        print("🗑️ Delete workout requested for id: \(id)")
        if let index = workouts.firstIndex(where: { $0.id == id }) {
            print("📍 Found workout at index: \(index)")
            print("📝 Workout details before deletion: \(workouts[index])")
            withAnimation {
                workouts.remove(at: index)
            }
            print("✅ Workout successfully removed from array")
        } else {
            print("❌ No workout found with id: \(id)")
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