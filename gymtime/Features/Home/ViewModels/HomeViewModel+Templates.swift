// 📄 Template management extensions for HomeViewModel

import Foundation
import SwiftUI

/// Represents a workout template that can be applied
struct WorkoutTemplate: Identifiable {
    let id: UUID
    let summary: String
    let date: Date
    
    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E M/d"  // e.g. "Mon 3/18"
        formatter.timeZone = TimeZone(identifier: "UTC") // Use UTC since dates are stored in UTC
        formatter.calendar = Calendar.current
        let formattedDate = formatter.string(from: date)
        print("📅 Template display - Raw date: \(date), Formatted: \(formattedDate), Timezone: \(formatter.timeZone.identifier)")
        return "\(summary) • \(formattedDate)"
    }
}

extension HomeViewModel {
    // MARK: - Template Management
    
    /// Loads recent workout templates and updates the published properties
    @MainActor
    func loadRecentTemplates() async {
        isLoadingTemplates = true
        defer { isLoadingTemplates = false }
        
        recentTemplates = await fetchRecentTemplates()
        print("🔄 Loaded \(recentTemplates.count) templates")
    }
    
    /// Applies a template to the current day
    @MainActor
    func applyTemplate(_ template: WorkoutTemplate) async {
        do {
            print("📋 Applying template from \(template.date.formatted()) to current day")
            
            // Fetch workouts from template date
            let templateWorkouts: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: try await supabase.auth.session.user.id)
                .eq("date", value: template.date)
                .order("created_at")
                .execute()
                .value
            
            print("📥 Found \(templateWorkouts.count) workouts to copy")
            
            // Create new workouts for today
            let today = Calendar.current.startOfDay(for: Date())
            let userId = try await supabase.auth.session.user.id
            
            for workout in templateWorkouts {
                let newWorkout = WorkoutEntry(
                    userId: userId,
                    exercise: workout.exercise,
                    muscleGroup: workout.muscleGroup,
                    weight: workout.weight,
                    sets: workout.sets,
                    reps: workout.reps,
                    date: today
                )
                
                // Add to local state first
                workouts.append(newWorkout)
                
                // Save to Supabase
                try await supabase
                    .from("workouts")
                    .insert(newWorkout)
                    .execute()
            }
            
            print("✅ Successfully copied \(templateWorkouts.count) workouts")
            
            // Generate new summary for today
            if !workouts.isEmpty {
                await generateWorkoutSummary()
            }
            
        } catch {
            print("❌ Error applying template: \(error)")
            self.error = "Failed to apply workout template"
        }
    }
    
    /// Fetches recent unique workout summaries to use as templates
    @MainActor
    func fetchRecentTemplates() async -> [WorkoutTemplate] {
        do {
            // Get current user ID
            let userId = try await supabase.auth.session.user.id
            
            // Fetch recent summaries
            let response: [DailyWorkoutSummary] = try await supabase
                .from("daily_workout_summaries")
                .select()
                .eq("user_id", value: userId)
                .neq("summary", value: "") // Only get days with non-empty summaries
                .order("date", ascending: false)
                .limit(10) // Fetch more than we need to account for duplicates
                .execute()
                .value
            
            print("📥 Fetched \(response.count) summaries from Supabase")
            if let firstDate = response.first?.date {
                print("📅 First summary date - Raw: \(firstDate), Local: \(firstDate.formatted())")
            }
            
            // Process into unique templates
            var uniqueSummaries: [String: WorkoutTemplate] = [:]
            
            for summary in response {
                if let summaryText = summary.summary,
                   !summaryText.isEmpty,
                   uniqueSummaries.count < 4, // Keep only 4 most recent unique summaries
                   uniqueSummaries[summaryText] == nil {
                    print("📝 Processing summary: \(summaryText) for date: \(summary.date.formatted())")
                    uniqueSummaries[summaryText] = WorkoutTemplate(
                        id: summary.id,
                        summary: summaryText,
                        date: summary.date
                    )
                }
            }
            
            // Return sorted by date
            let templates = Array(uniqueSummaries.values)
                .sorted { $0.date > $1.date }
            
            print("✅ Returning \(templates.count) unique templates")
            return templates
            
        } catch {
            print("❌ Error fetching workout templates: \(error)")
            return []
        }
    }
} 