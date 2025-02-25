// 📄 Workout management extensions for HomeViewModel

import Foundation
import SwiftUI
import Supabase

extension HomeViewModel {
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
                
                let response: [WorkoutEntry] = try await supabase
                    .from("workouts")
                    .select()
                    .eq("user_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                // Filter workouts for selected date
                let calendar = Calendar.current
                let filteredWorkouts = response.filter { workout in
                    calendar.isDate(workout.date, equalTo: calendarState.selectedDate, toGranularity: .day)
                }
                
                print("✅ Loaded \(filteredWorkouts.count) workouts for selected date")
                
                // Update UI
                await MainActor.run {
                    self.workouts = filteredWorkouts
                    
                    // Generate summary if we have workouts
                    if !filteredWorkouts.isEmpty {
                        Task {
                            await loadDailySummary()
                            if self.aiWorkoutSummary.isEmpty {
                                await generateWorkoutSummary()
                            }
                        }
                    } else {
                        self.aiWorkoutSummary = ""
                    }
                }
                
                // Update calendar with workout dates
                await loadWorkoutDates()
                
            } catch {
                print("Error loading workouts: \(error)")
                self.error = "Failed to load workouts"
            }
        }
    }
    
    func loadWorkoutDates() async {
        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                print("Error: No user ID found when loading workout dates")
                return
            }
            
            // Query just the dates column to be efficient
            let response: [WorkoutDateResponse] = try await supabase
                .from("workouts")
                .select("date")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // Create a set of unique dates
            let workoutDates = Set(response.map { $0.date })
            print("✅ Found workouts on \(workoutDates.count) different dates")
            
            // Update the calendar state with these dates
            await MainActor.run {
                var updatedState = self.calendarState
                updatedState.updateWorkoutDates(workoutDates)
                self.calendarState = updatedState
            }
            
        } catch {
            print("Error loading workout dates: \(error)")
        }
    }
    
    // Helper struct for date-only response
    private struct WorkoutDateResponse: Decodable {
        let date: Date
        
        enum CodingKeys: String, CodingKey {
            case date
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode date with timezone information
            let dateString = try container.decode(String.self, forKey: .date)
            
            // Create a date formatter for date-only format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            
            if let parsedDate = formatter.date(from: dateString) {
                // Set to start of day in local timezone
                date = Calendar.current.startOfDay(for: parsedDate)
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Date string does not match expected format: \(dateString)"
                ))
            }
        }
    }
    
    func addWorkout(_ workout: WorkoutEntry) {
        // Add to local state immediately
        withAnimation {
            workouts.insert(workout, at: 0)
        }
        
        // Save to Supabase
        Task {
            do {
                try await supabase
                    .from("workouts")
                    .insert(workout)
                    .execute()
                
                print("✅ Workout saved to Supabase")
                
                // Generate new summary
                await generateWorkoutSummary()
                
                // Update calendar workout dates
                await loadWorkoutDates()
                
            } catch {
                print("❌ Failed to save workout: \(error)")
                
                // Remove from local state if save failed
                if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                    workouts.remove(at: index)
                }
                
                self.error = "Failed to save workout"
            }
        }
    }
    
    func updateWorkoutField(id: UUID, field: String, value: String) {
        print("🔄 Updating workout field:")
        print("   ID: \(id)")
        print("   Field: \(field)")
        print("   Value: \(value)")
        
        // Find workout in local state
        guard let index = workouts.firstIndex(where: { $0.id == id }) else {
            print("❌ No workout found with id: \(id)")
            return
        }
        
        // Store previous state for rollback
        let previousWorkout = workouts[index]
        
        // Create updated workout
        var updatedWorkout = previousWorkout
        
        // Update the specified field
        switch field {
        case "exercise":
            updatedWorkout.exercise = value
        case "weight":
            updatedWorkout.weight = Double(value)
        case "sets":
            updatedWorkout.sets = Int(value)
        case "reps":
            updatedWorkout.reps = Int(value)
        case "notes":
            updatedWorkout.notes = value
        default:
            return
        }
        
        // Optimistically update UI
        workouts[index] = updatedWorkout
        
        // Update Supabase
        Task {
            do {
                try await supabase
                    .from("workouts")
                    .update([field: value])
                    .eq("id", value: id)
                    .execute()
                
                print("✅ Successfully updated workout field: \(field)")
            } catch {
                print("❌ Failed to update workout: \(error)")
                // Rollback on failure
                DispatchQueue.main.async {
                    self.workouts[index] = previousWorkout
                    self.error = "Failed to update workout"
                }
            }
        }
    }
    
    func deleteWorkout(id: UUID) {
        print("🗑️ Delete workout requested for id: \(id)")
        
        // Check if the workout is still in the array (it might have been removed already)
        let workoutToDelete = workouts.first(where: { $0.id == id })
        
        // If the workout is still in the array, remove it
        if let workoutToDelete = workoutToDelete, let index = workouts.firstIndex(where: { $0.id == id }) {
            print("📍 Found workout at index: \(index)")
            print("📝 Workout details before deletion: \(workoutToDelete)")
            
            // Remove from local state
            workouts.remove(at: index)
        } else {
            print("ℹ️ Workout already removed from local array, proceeding with Supabase deletion")
        }
        
        // Delete from Supabase regardless of whether it was in the local array
        Task {
            do {
                // Convert UUID to string explicitly
                let idString = id.uuidString
                print("🔍 Attempting to delete workout with ID string: \(idString)")
                
                // Try with more detailed error handling
                let response = try await supabase
                    .from("workouts")
                    .delete()
                    .eq("id", value: idString)  // Use string representation
                    .execute()
                
                print("✅ Workout successfully deleted from Supabase with response: \(response)")
                
                // Update calendar workout dates after deletion
                await loadWorkoutDates()
            } catch {
                print("❌ Failed to delete workout from Supabase: \(error)")
                print("❌ Error details: \(String(describing: error))")
                
                // Only attempt to restore if we had the workout details
                if let workoutToDelete = workoutToDelete {
                    DispatchQueue.main.async {
                        self.workouts.append(workoutToDelete)
                        self.error = "Failed to delete workout"
                    }
                }
            }
        }
    }
}