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
        return "\(summary) • \(formatter.string(from: date))"
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
            
            // Process into unique templates
            var uniqueSummaries: [String: WorkoutTemplate] = [:]
            
            for summary in response {
                if let summaryText = summary.summary,
                   !summaryText.isEmpty,
                   uniqueSummaries.count < 4, // Keep only 4 most recent unique summaries
                   uniqueSummaries[summaryText] == nil {
                    uniqueSummaries[summaryText] = WorkoutTemplate(
                        id: summary.id,
                        summary: summaryText,
                        date: summary.date
                    )
                }
            }
            
            // Return sorted by date
            return Array(uniqueSummaries.values)
                .sorted { $0.date > $1.date }
            
        } catch {
            print("❌ Error fetching workout templates: \(error)")
            return []
        }
    }
} 