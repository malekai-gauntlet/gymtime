/*
 * 🧠 What is this file for?
 * -------------------------
 * This is the view model that manages the user's profile data and statistics.
 * It handles loading and calculating workout progress, milestones, and achievements.
 */

import SwiftUI
import Combine
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    // User Info
    @Published var username: String?
    @Published var displayName: String?
    
    // Stats
    @Published var totalWorkouts: Int = 0
    @Published var workoutsThisWeek: Int = 0
    @Published var weeklyGoal: Int = 3
    @Published var currentStreak: Int = 0
    @Published var personalRecords: Int = 0
    
    // Milestones and Progress
    @Published var milestones: [Milestone] = []
    @Published var progressData: [ProgressPoint] = []
    
    // Loading and Error States
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // Add this property
    @Published var isAnonymous: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // No automatic loading on init
    }
    
    // Public method to refresh all profile data
    func refreshProfile() async {
        do {
            isLoading = true
            error = nil
            
            await loadUserProfile()
            await loadWorkoutStats()
            await calculateMilestones()
            await loadProgressData()
        } catch {
            self.error = "Failed to refresh profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Update profile information
    func updateProfile(username: String, fullName: String) async throws {
        guard !username.isEmpty && !fullName.isEmpty else {
            throw ProfileError.invalidInput("Username and full name are required")
        }
        
        do {
            isLoading = true
            error = nil
            
            let userId = try await supabase.auth.session.user.id
            
            // Update profile in Supabase
            try await supabase
                .from("profiles")
                .update([
                    "username": username,
                    "full_name": fullName
                ])
                .eq("id", value: userId)
                .execute()
            
            // Refresh profile data
            await loadUserProfile()
            
        } catch {
            self.error = "Failed to update profile: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    private func loadUserProfile() async {
        do {
            isLoading = true
            
            // Get current user session
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            // Fetch profile data from profiles table
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            // Update UI with either profile data or default anonymous values
            if profile.username?.isEmpty ?? true && profile.fullName?.isEmpty ?? true {
                // User is anonymous - use default values
                username = "anonymous"
                displayName = "Anonymous User"
                isAnonymous = true
            } else {
                // Use actual profile data
                username = profile.username
                displayName = profile.fullName?.isEmpty ?? true ? profile.username : profile.fullName
                isAnonymous = false
            }
            
        } catch {
            self.error = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    private func loadWorkoutStats() async {
        do {
            let userId = try await supabase.auth.session.user.id
            
            // Get total workouts
            let totalResponse: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            totalWorkouts = totalResponse.count
            
            // Get workouts this week
            let calendar = Calendar.current
            let weekStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date())
            
            workoutsThisWeek = totalResponse.filter { workout in
                workout.date >= weekStart
            }.count
            
            // Calculate streak
            let sortedDates = totalResponse
                .map { $0.date }
                .sorted(by: >)
                .map { calendar.startOfDay(for: $0) }
            
            var streak = 0
            var currentDate = calendar.startOfDay(for: Date())
            
            while sortedDates.contains(currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? Date()
            }
            
            currentStreak = streak
            
            // Count personal records (workouts with highest weight for each exercise)
            var exerciseMaxes: [String: Double] = [:]
            for workout in totalResponse {
                if let weight = workout.weight {
                    if let currentMax = exerciseMaxes[workout.exercise] {
                        if weight > currentMax {
                            exerciseMaxes[workout.exercise] = weight
                        }
                    } else {
                        exerciseMaxes[workout.exercise] = weight
                    }
                }
            }
            
            personalRecords = exerciseMaxes.count
            
        } catch {
            self.error = "Failed to load workout stats: \(error.localizedDescription)"
        }
    }
    
    private func calculateMilestones() async {
        do {
            let userId = try await supabase.auth.session.user.id
            
            let workouts: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            var newMilestones: [Milestone] = []
            
            // First Workout Milestone - Removed as requested
            
            // 10 Workouts Milestone
            if workouts.count >= 10 {
                newMilestones.append(
                    Milestone(id: 1, title: "10 Workouts", iconName: "flame.fill", color: .orange)
                )
            }
            
            // 20 Workouts Milestone - For intense gym goers
            if workouts.count >= 20 {
                newMilestones.append(
                    Milestone(id: 5, title: "Iron Warrior", iconName: "dumbbell.fill", color: .red)
                )
            }
            
            // Streak Milestone
            if currentStreak >= 7 {
                newMilestones.append(
                    Milestone(id: 2, title: "1 Week Streak", iconName: "star.fill", color: .yellow)
                )
            }
            
            // Weight Milestone (100kg/225lbs on any exercise)
            if workouts.contains(where: { $0.weight ?? 0 >= 225 }) {
                newMilestones.append(
                    Milestone(id: 3, title: "225lb Club", iconName: "bolt.fill", color: .purple)
                )
            }
            
            // Consistency Milestone (workouts on 3+ different exercises)
            let uniqueExercises = Set(workouts.map { $0.exercise })
            if uniqueExercises.count >= 3 {
                newMilestones.append(
                    Milestone(id: 4, title: "Diverse Training", iconName: "figure.mixed.cardio", color: .blue)
                )
            }
            
            // Debug logging to verify milestone calculation
            print("Calculated \(newMilestones.count) milestones")
            print("Workouts count: \(workouts.count)")
            print("Current streak: \(currentStreak)")
            print("Has 225+ workout: \(workouts.contains(where: { $0.weight ?? 0 >= 225 }))")
            print("Unique exercises: \(uniqueExercises.count)")
            
            milestones = newMilestones
            
        } catch {
            self.error = "Failed to calculate milestones: \(error.localizedDescription)"
        }
    }
    
    private func loadProgressData() async {
        do {
            let userId = try await supabase.auth.session.user.id
            
            // Get last 14 days of workouts (changed from 7 to show more data like Strava)
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date())
            
            let workouts: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .gte("date", value: startDate)
                .order("date")
                .execute()
                .value
            
            // Group workouts by date and calculate daily volume (weight * sets * reps)
            var dailyVolume: [Date: Double] = [:]
            
            for workout in workouts {
                let date = calendar.startOfDay(for: workout.date)
                let volume = (workout.weight ?? 0) * Double(workout.sets ?? 0) * Double(workout.reps ?? 0)
                dailyVolume[date, default: 0] += volume
            }
            
            // Create progress points
            var points: [ProgressPoint] = []
            var currentDate = startDate
            let endDate = calendar.startOfDay(for: Date())
            
            // Find max volume for percentage calculation
            let maxVolume = dailyVolume.values.max() ?? 1
            
            while currentDate <= endDate {
                let volume = dailyVolume[currentDate] ?? 0
                let percentage = (volume / maxVolume) * 100
                
                // Store both the percentage (for scaling the chart) and actual volume (for tooltips/debugging)
                points.append(ProgressPoint(
                    date: currentDate, 
                    value: percentage,
                    actualVolume: volume  // Store the actual total weight lifted
                ))
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            progressData = points
            
        } catch {
            self.error = "Failed to load progress data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    // Add this near the other public methods
    func deleteAccount() async throws {
        do {
            isLoading = true
            error = nil
            
            print("🔄 Starting account deletion from ProfileViewModel...")
            
            // Get user ID for logging
            if let userId = try? await supabase.auth.session.user.id {
                print("📍 Initiating deletion for user: \(userId)")
            }
            
            // Use the AuthenticationViewModel to delete the user
            let authViewModel = AuthenticationViewModel(coordinator: AppCoordinator())
            try await authViewModel.deleteUser()
            print("✅ Account deletion completed successfully")
            
            isLoading = false
        } catch {
            isLoading = false
            print("❌ Account deletion failed: \(error.localizedDescription)")
            self.error = "Failed to delete account: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - Models

struct Milestone: Identifiable {
    let id: Int
    let title: String
    let iconName: String
    let color: Color
}

struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double // Percentage of max volume
    let actualVolume: Double // Actual total weight lifted
}

// MARK: - Profile Model
struct Profile: Codable {
    let id: UUID
    let username: String?
    let fullName: String?
    let hasSeenOnboarding: Bool
    let hasSeenWeightsTooltip: Bool
    let hasSeenFeedTooltip: Bool
    let hasSeenProfileTooltip: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case hasSeenOnboarding = "has_seen_onboarding"
        case hasSeenWeightsTooltip = "has_seen_weights_tooltip"
        case hasSeenFeedTooltip = "has_seen_feed_tooltip"
        case hasSeenProfileTooltip = "has_seen_profile_tooltip"
    }
}

// MARK: - Error Types
enum ProfileError: Error {
    case updateFailed
    case exportFailed
    case invalidInput(String)  // Add back the invalidInput case with an associated string value
}

extension ProfileViewModel {
    // Export workouts to CSV
    func exportWorkoutsToCSV() async throws -> String {
        // CSV Headers
        let headers = ["Date", "Exercise", "Weight", "Sets", "Reps", "Notes", "Muscle Group"]
        var csvString = headers.joined(separator: ",") + "\n"
        
        do {
            // Get current user ID
            guard let userId = try? await supabase.auth.session.user.id else {
                throw ProfileError.exportFailed
            }
            
            // Fetch all workouts for the user
            let workouts: [WorkoutEntry] = try await supabase
                .from("workouts")
                .select()
                .eq("user_id", value: userId)
                .order("date", ascending: true)
                .execute()
                .value
            
            // Format each workout as a CSV row
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for workout in workouts {
                let row = [
                    dateFormatter.string(from: workout.date),
                    workout.exercise.replacingOccurrences(of: ",", with: ";"),  // Escape commas
                    workout.weight.map { String($0) } ?? "",
                    workout.sets.map { String($0) } ?? "",
                    workout.reps.map { String($0) } ?? "",
                    workout.notes?.replacingOccurrences(of: ",", with: ";") ?? "",  // Escape commas
                    workout.muscleGroup?.replacingOccurrences(of: ",", with: ";") ?? ""  // Escape commas
                ]
                csvString += row.joined(separator: ",") + "\n"
            }
            
            return csvString
        } catch {
            throw ProfileError.exportFailed
        }
    }

    // Handle export errors
    func handleExportError(_ error: Error) {
        self.error = "Failed to export workouts: \(error.localizedDescription)"
    }
}
