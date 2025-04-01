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
        print("🏋️ Starting workout save process...")
        print("📍 Initial workout location: \(workout.location ?? "nil")")
        
        // Add to local state immediately for instant UI feedback
        withAnimation {
            workouts.insert(workout, at: 0)
            print("✨ Added workout to local state immediately")
        }
        
        // Save to Supabase with location
        Task {
            do {
                print("📡 Attempting to save workout to Supabase...")
                
                // Get location string before saving
                var workoutWithLocation = workout
                print("📍 Getting location string from LocationManager...")
                
                // Properly await the location string
                let locationString = await LocationManager.shared.getLocationString()
                print("📍 Location received - Location: \(locationString ?? "nil")")
                workoutWithLocation.location = locationString
                
                print("📍 Final workout location before save: \(workoutWithLocation.location ?? "nil")")
                
                // Debug print the full workout object
                print("📝 Full workout object being sent to Supabase:")
                print("   - ID: \(workoutWithLocation.id)")
                print("   - Exercise: \(workoutWithLocation.exercise)")
                print("   - Location: \(workoutWithLocation.location ?? "nil")")
                print("   - Weight: \(workoutWithLocation.weight ?? 0)")
                print("   - Sets: \(workoutWithLocation.sets ?? 0)")
                print("   - Reps: \(workoutWithLocation.reps ?? 0)")
                print("   - Date: \(workoutWithLocation.date)")
                
                // 1. Save workout with location
                try await supabase
                    .from("workouts")
                    .insert(workoutWithLocation)
                    .execute()
                
                print("✅ Workout saved to Supabase successfully")
                
                // Update local state with location if needed
                if workout.location != workoutWithLocation.location {
                    print("📍 Updating local state with new location: \(workoutWithLocation.location ?? "nil")")
                    await MainActor.run {
                        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                            workouts[index].location = workoutWithLocation.location
                            print("✅ Local state updated with location")
                        } else {
                            print("❌ Could not find workout in local state to update location")
                        }
                    }
                } else {
                    print("📍 No location update needed for local state")
                }
                
                // 2. Quick check if user is anonymous (fast operation)
                print("🔍 Checking if user is anonymous...")
                let session = try await supabase.auth.session
                let userEmail = session.user.email
                print("📧 Debug - User email: \(userEmail ?? "nil")")
                print("🔍 Debug - Session details: \(String(describing: session.user))")
                
                let isAnonymous = userEmail == nil || userEmail == "-" || userEmail?.isEmpty == true
                print("👤 User anonymous status: \(isAnonymous)")
                print("📊 Current totalWorkoutCount: \(totalWorkoutCount)")
                print("🎯 showAnonymousConversion status: \(showAnonymousConversion)")
                
                // 3. Only proceed with count check if anonymous
                if isAnonymous {
                    print("🔄 User is anonymous, proceeding with count check...")
                    
                    // Check current count only if we haven't shown conversion yet
                    if !showAnonymousConversion && totalWorkoutCount < 6 {
                        print("📝 Conditions met for workout count check:")
                        print("   - Haven't shown conversion: ✅")
                        print("   - Total count < 6: ✅")
                        
                        // Get total workout count in background
                        print("🔢 Fetching total workout count...")
                        let response: [WorkoutEntry] = try await supabase
                            .from("workouts")
                            .select()
                            .eq("user_id", value: session.user.id)
                            .execute()
                            .value
                        
                        let count = response.count
                        print("📊 Retrieved total workout count: \(count)")
                        
                        // Update UI if we hit exactly 5
                        await MainActor.run {
                            self.totalWorkoutCount = count
                            print("🔄 Updated totalWorkoutCount to: \(count)")
                            
                            if count == 5 {
                                print("🎯 Hit exactly 5 workouts! Showing conversion view...")
                                self.showAnonymousConversion = true
                                print("🚀 Set showAnonymousConversion to true")
                            }
                        }
                    } else {
                        print("⏭️ Skipping count check because:")
                        print("   - showAnonymousConversion: \(showAnonymousConversion)")
                        print("   - totalWorkoutCount: \(totalWorkoutCount)")
                    }
                } else {
                    print("⏭️ Skipping anonymous checks - user has email")
                }
                
                // Continue with other background tasks
                print("🔄 Proceeding with background tasks...")
                await generateWorkoutSummary()
                await loadWorkoutDates()
                
            } catch {
                print("❌ Failed to save workout: \(error)")
                print("❌ Error details: \(String(describing: error))")
                
                // Remove from local state if save failed
                if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                    workouts.remove(at: index)
                }
                
                self.error = "Failed to save workout"
            }
        }
    }
    
    func updateWorkoutField(id: UUID, field: String, value: String) {
        Task {
            do {
                // Update local state immediately
                if let index = workouts.firstIndex(where: { $0.id == id }) {
                    switch field {
                    case "exercise":
                        workouts[index].exercise = value
                    case "weight":
                        workouts[index].weight = Double(value)
                    case "sets":
                        workouts[index].sets = Int(value)
                    case "reps":
                        workouts[index].reps = Int(value)
                    case "notes":
                        workouts[index].notes = value
                    default:
                        break
                    }
                }
                
                // Update in Supabase
                try await supabase
                    .from("workouts")
                    .update([field: value])
                    .eq("id", value: id)
                    .execute()
                
            } catch {
                print("Error updating workout: \(error)")
                self.error = "Failed to update workout"
            }
        }
    }
    
    // Add new function for toggling workout completion
    func toggleWorkoutCompletion(id: UUID) {
        Task {
            do {
                // Update local state immediately for responsive UI
                if let index = workouts.firstIndex(where: { $0.id == id }) {
                    // Toggle the completion state
                    workouts[index].isCompleted.toggle()
                    let newCompletionState = workouts[index].isCompleted
                    let currentWorkout = workouts[index]
                    
                    print("🔄 Toggling workout completion - ID: \(id), New state: \(newCompletionState)")
                    
                    // Update in Supabase
                    try await supabase
                        .from("workouts")
                        .update(["is_completed": newCompletionState])
                        .eq("id", value: id)
                        .execute()
                    
                    print("✅ Successfully updated workout completion state in Supabase")
                    
                    // Only check for PB if the workout is being marked as complete and has a weight
                    if newCompletionState, let weight = currentWorkout.weight {
                        // Query for historical max weight for this exercise
                        let response: [WorkoutEntry] = try await supabase
                            .from("workouts")
                            .select()
                            .eq("user_id", value: currentWorkout.userId)
                            .eq("exercise", value: currentWorkout.exercise)
                            .not("id", operator: .eq, value: currentWorkout.id) // Exclude current workout
                            .execute()
                            .value
                        
                        // Find the maximum weight from historical workouts
                        let historicalMax = response.compactMap { $0.weight }.max() ?? 0
                        
                        // If current weight is higher than historical max, it's a PB
                        if weight > historicalMax {
                            print("🎉 New PB achieved for \(currentWorkout.exercise): \(weight) lbs")
                            newPbInfo = PBInfo(
                                exercise: currentWorkout.exercise,
                                weight: weight,
                                sets: currentWorkout.sets,
                                reps: currentWorkout.reps
                            )
                        }
                    }
                }
            } catch {
                print("❌ Error toggling workout completion: \(error)")
                self.error = "Failed to update workout completion status"
                
                // Revert local state if update failed
                if let index = workouts.firstIndex(where: { $0.id == id }) {
                    workouts[index].isCompleted.toggle()
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