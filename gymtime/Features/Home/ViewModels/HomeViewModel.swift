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
    @Published var aiWorkoutSummary: String = ""
    
    // MARK: - Computed Properties
    
    var workoutSummary: String {
        // If no workouts, return empty string
        guard !workouts.isEmpty else { return "" }
        
        // Get unique exercises
        let exercises = Set(workouts.map { $0.exercise.split(separator: " ").first?.description ?? $0.exercise })
        
        // If only one type of exercise
        if exercises.count == 1 {
            return exercises.first!
        }
        
        // If 2-3 exercises, join with +
        if exercises.count <= 3 {
            return exercises.joined(separator: " + ")
        }
        
        // If more than 3, show first two and count
        let first = Array(exercises.prefix(2))
        return "\(first.joined(separator: " + ")) +\(exercises.count - 2)"
    }
    
    private func generateWorkoutSummary() async {
        guard !workouts.isEmpty else {
            self.aiWorkoutSummary = ""
            return
        }
        
        // Create a simple description of the workouts
        let workoutDescriptions = workouts.map { workout in
            "\(workout.exercise) (\(workout.sets ?? 0)x\(workout.reps ?? 0))"
        }.joined(separator: ", ")
        
        do {
            let prompt = "Summarize this workout in 3-4 words (e.g. 'Upper Body + Core', 'Full Body Circuit', 'Legs + Cardio', 'Push Day', or 'Back & Biceps'): \(workoutDescriptions)"
            
            let summary = try await workoutParser.summarizeWorkout(text: prompt)
            self.aiWorkoutSummary = summary
        } catch {
            print("Failed to generate workout summary: \(error)")
            // Fallback to basic summary
            self.aiWorkoutSummary = self.workoutSummary
        }
    }
    
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
        print("🗓️ User selected new date: \(date)")
        calendarState.selectDate(date)
        loadWorkouts()  // Reload and filter workouts for the new date
    }
    
    // MARK: - Swipe Gesture Logging
    
    func logSwipeGestureStart() {
        print("👆 Swipe gesture started")
    }
    
    func logSwipeGestureEnd(direction: String, succeeded: Bool) {
        print("👆 Swipe gesture ended")
        print("   Direction: \(direction)")
        print("   Successfully changed date: \(succeeded)")
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
                // Get current user ID
                guard let userId = try? await supabase.auth.session.user.id else {
                    print("Error: No user ID found")
                    self.error = "Please log in to view workouts"
                    return
                }
                
                print("📅 Loading workouts for selected date: \(calendarState.selectedDate)")
                
                let response: [WorkoutEntry] = try await supabase.database
                    .from("workouts")
                    .select()
                    .eq("user_id", value: userId)  // Filter by user_id
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                print("📊 Fetched \(response.count) total workouts from Supabase")
                print("🔍 Workout dates from Supabase:")
                response.forEach { workout in
                    print("   • Workout ID: \(workout.id)")
                    print("     Exercise: \(workout.exercise)")
                    print("     Date in DB: \(workout.date)")
                }
                
                DispatchQueue.main.async {
                    self.workouts = response
                    print("🔄 About to filter workouts for date: \(self.calendarState.selectedDate)")
                    self.filterWorkoutsForSelectedDate()
                }
            } catch {
                print("Error loading workouts: \(error)")
                self.error = "Failed to load workouts"
            }
        }
    }
    
    private func filterWorkoutsForSelectedDate() {
        let calendar = Calendar.current
        let selectedDate = calendarState.selectedDate
        print("\n📆 Filtering workouts for selected date: \(selectedDate)")
        print("Before filtering: \(workouts.count) workouts")
        
        workouts = workouts.filter { workout in
            let isMatch = calendar.isDate(workout.date, equalTo: selectedDate, toGranularity: .day)
            print("   • Workout: \(workout.exercise)")
            print("     Date: \(workout.date)")
            print("     Matches selected date? \(isMatch)")
            return isMatch
        }
        
        print("After filtering: \(workouts.count) workouts remain\n")
        
        // Generate new summary when workouts change
        Task {
            await generateWorkoutSummary()
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
        
        // Store the index before deletion for rollback if needed
        guard let index = workouts.firstIndex(where: { $0.id == id }) else {
            print("❌ No workout found with id: \(id)")
            return
        }
        
        let deletedWorkout = workouts[index]
        print("📍 Found workout at index: \(index)")
        print("📝 Workout details before deletion: \(deletedWorkout)")
        
        // Remove from local state immediately for responsive UI
        withAnimation {
            workouts.remove(at: index)
        }
        
        // Delete from Supabase
        Task {
            do {
                try await supabase.database
                    .from("workouts")
                    .delete()
                    .eq("id", value: id)
                    .execute()
                
                print("✅ Workout successfully deleted from Supabase")
            } catch {
                print("❌ Failed to delete workout from Supabase: \(error)")
                // Rollback local state if Supabase deletion fails
                DispatchQueue.main.async {
                    self.workouts.insert(deletedWorkout, at: index)
                    self.error = "Failed to delete workout"
                }
            }
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