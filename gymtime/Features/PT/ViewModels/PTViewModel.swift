// 📄 ViewModel for injury prevention analysis and insights

import Foundation
import SwiftUI
import Combine

@MainActor
class PTViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The current analysis results
    @Published private(set) var analysisResults: WorkoutAnalysis?
    
    /// Loading state for analysis
    @Published private(set) var isLoading = false
    
    /// Error state
    @Published private(set) var error: String?
    
    // MARK: - Private Properties
    
    /// Reference to the HomeViewModel for workout data
    private let homeViewModel: HomeViewModel
    
    /// Analyzer instance for processing workout data
    private let analyzer: MuscleBalanceAnalyzer
    
    /// Task for handling analysis updates
    private var analysisTask: Task<Void, Never>?
    
    /// Store our cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(homeViewModel: HomeViewModel, analyzer: MuscleBalanceAnalyzer = MuscleBalanceAnalyzer()) {
        self.homeViewModel = homeViewModel
        self.analyzer = analyzer
        
        // Start observing workout changes
        setupWorkoutObserver()
    }
    
    // MARK: - Public Methods
    
    /// Manually trigger a refresh of the analysis
    func refreshAnalysis() async {
        await analyzeWorkouts()
    }
    
    // MARK: - Private Methods
    
    private func setupWorkoutObserver() {
        // Observe changes to workouts array
        homeViewModel.$workouts
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)  // Prevent rapid updates
            .sink { [weak self] _ in
                Task {
                    await self?.analyzeWorkouts()
                }
            }
            .store(in: &cancellables)
    }
    
    private func analyzeWorkouts() async {
        // Cancel any existing analysis task
        analysisTask?.cancel()
        
        do {
            isLoading = true
            error = nil
            
            // Check if there are any workouts
            guard !homeViewModel.workouts.isEmpty else {
                // Clear any existing analysis and set a friendly message
                self.analysisResults = nil
                self.error = nil
                self.isLoading = false
                return
            }
            
            // Convert HomeViewModel workouts to analyzer format
            let workoutEntries = homeViewModel.workouts.map { workout in
                MuscleBalanceAnalyzer.WorkoutEntry(
                    exercise: workout.exercise,
                    weight: workout.weight ?? 0,
                    sets: workout.sets ?? 0,
                    reps: workout.reps ?? 0,
                    date: workout.date
                )
            }
            
            // Perform analysis
            let analysis = try analyzer.analyzeWorkouts(workoutEntries)
            
            // Update UI
            self.analysisResults = analysis
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the strength score for a specific muscle group
    func strengthScore(for muscleGroup: String) -> Double {
        analysisResults?.muscleGroups[muscleGroup]?.strengthScore ?? 0
    }
    
    /// Check if a muscle group needs attention
    func needsAttention(_ muscleGroup: String) -> Bool {
        analysisResults?.needsAttention(muscleGroup) ?? false
    }
    
    /// Get all current warnings
    var warnings: [String] {
        analysisResults?.warnings ?? []
    }
    
    /// Get all current recommendations
    var recommendations: [String] {
        analysisResults?.recommendations ?? []
    }
    
    /// Check if push/pull ratio is balanced
    var isPushPullBalanced: Bool {
        analysisResults?.isPushPullBalanced ?? false
    }
}

// MARK: - Preview Helper

extension PTViewModel {
    /// Creates a preview instance with sample data
    static var preview: PTViewModel {
        // Create a mock HomeViewModel for previews
        let mockHomeVM = HomeViewModel()
        
        // Directly set workouts without loading from Supabase
        let sampleWorkouts: [WorkoutEntry] = [
            .init(
                id: UUID(),
                userId: UUID(), // Add mock user ID
                exercise: "Bench Press",
                weight: 185,
                sets: 3,
                reps: 8,
                date: Date()
            ),
            .init(
                id: UUID(),
                userId: UUID(), // Add mock user ID
                exercise: "Pull-ups",
                weight: nil,
                sets: 3,
                reps: 12,
                date: Date()
            ),
            .init(
                id: UUID(),
                userId: UUID(), // Add mock user ID
                exercise: "Squats",
                weight: 225,
                sets: 4,
                reps: 6,
                date: Date()
            )
        ]
        
        // Set workouts directly without triggering Supabase load
        mockHomeVM.workouts = sampleWorkouts
        
        return PTViewModel(homeViewModel: mockHomeVM)
    }
} 