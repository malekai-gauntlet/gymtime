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
                
            } catch {
                print("Error loading workouts: \(error)")
                self.error = "Failed to load workouts"
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
        
        // Store the index before deletion for rollback if needed
        guard let index = workouts.firstIndex(where: { $0.id == id }) else {
            print("❌ No workout found with id: \(id)")
            return
        }
        
        let deletedWorkout = workouts[index]
        print("📍 Found workout at index: \(index)")
        print("📝 Workout details before deletion: \(deletedWorkout)")
        
        // Remove from local state immediately for responsive UI
        _ = withAnimation {
            workouts.remove(at: index)
        }
        
        // Delete from Supabase
        Task {
            do {
                try await supabase
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
}