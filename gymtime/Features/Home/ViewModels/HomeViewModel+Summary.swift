// 📄 Workout summary management extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Summary Management
    
    func generateWorkoutSummary() async {
        guard !workouts.isEmpty else {
            self.aiWorkoutSummary = ""
            return
        }
        
        // Create workout description for AI
        let workoutDescriptions = workouts.map { workout in
            "\(workout.exercise) (\(workout.sets ?? 0)x\(workout.reps ?? 0))"
        }.joined(separator: ", ")
        
        do {
            let prompt = "Summarize this workout in 3-4 words (e.g. 'Upper Body + Core', 'Full Body Circuit', 'Legs + Cardio', 'Push Day', or 'Back & Biceps'): \(workoutDescriptions)"
            
            // Get summary from AI
            let summary = try await workoutParser.summarizeWorkout(text: prompt)
            
            // Save to Supabase
            let dailySummary = DailyWorkoutSummary(
                userId: try await supabase.auth.session.user.id,
                date: calendarState.selectedDate,
                summary: summary
            )
            
            try await supabase
                .from("daily_workout_summaries")
                .upsert(dailySummary, onConflict: "user_id,date")
                .execute()
            
            // Update UI and cache
            await MainActor.run {
                self.aiWorkoutSummary = summary
                self.summaryCache[calendarState.selectedDate] = summary
            }
            
        } catch {
            print("❌ Failed to generate/save workout summary: \(error)")
            await MainActor.run {
                self.aiWorkoutSummary = ""
            }
        }
    }
    
    func loadDailySummary() async {
        // Check cache first
        if let cachedSummary = summaryCache[calendarState.selectedDate] {
            self.aiWorkoutSummary = cachedSummary
            return
        }
        
        // Clear summary if no workouts
        if workouts.isEmpty {
            self.aiWorkoutSummary = ""
            return
        }
        
        do {
            let response: [DailyWorkoutSummary] = try await supabase
                .from("daily_workout_summaries")
                .select()
                .eq("user_id", value: try await supabase.auth.session.user.id)
                .eq("date", value: calendarState.selectedDate)
                .execute()
                .value
            
            // Update UI and cache
            let summary = response.first?.summary ?? ""
            await MainActor.run {
                self.aiWorkoutSummary = summary
                self.summaryCache[calendarState.selectedDate] = summary
            }
            
        } catch {
            print("❌ Error loading daily summary: \(error)")
            self.aiWorkoutSummary = ""
        }
    }
} 