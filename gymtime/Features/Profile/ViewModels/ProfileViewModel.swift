/*
 * 🧠 What is this file for?
 * -------------------------
 * This is the view model that manages the user's profile data and statistics.
 * It handles loading and calculating workout progress, milestones, and achievements.
 */

import SwiftUI
import Combine

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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserProfile()
        setupMockData() // TODO: Replace with actual data loading
    }
    
    private func loadUserProfile() {
        // TODO: Load from UserDefaults or API
        username = "malekai"
        displayName = "Malekai M"
    }
    
    private func setupMockData() {
        // Mock stats
        totalWorkouts = 42
        workoutsThisWeek = 2
        weeklyGoal = 3
        currentStreak = 4
        personalRecords = 12
        
        // Mock milestones
        milestones = [
            Milestone(id: 1, title: "First Workout", iconName: "figure.walk", color: .green),
            Milestone(id: 2, title: "10 Workouts", iconName: "flame.fill", color: .orange),
            Milestone(id: 3, title: "1 Month Streak", iconName: "star.fill", color: .yellow),
            Milestone(id: 4, title: "100kg Squat", iconName: "bolt.fill", color: .purple),
            Milestone(id: 5, title: "Marathon Ready", iconName: "figure.run", color: .blue)
        ]
        
        // Mock progress data (last 7 days)
        progressData = [
            ProgressPoint(date: Date().addingTimeInterval(-6 * 86400), value: 65),
            ProgressPoint(date: Date().addingTimeInterval(-5 * 86400), value: 70),
            ProgressPoint(date: Date().addingTimeInterval(-4 * 86400), value: 68),
            ProgressPoint(date: Date().addingTimeInterval(-3 * 86400), value: 75),
            ProgressPoint(date: Date().addingTimeInterval(-2 * 86400), value: 72),
            ProgressPoint(date: Date().addingTimeInterval(-1 * 86400), value: 80),
            ProgressPoint(date: Date(), value: 78)
        ]
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
    let value: Double // Percentage or actual value
}
