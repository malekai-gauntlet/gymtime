// 📄 Manages state and business logic for the home screen

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntry] = []
    @Published var selectedDate: Date = Date()
    
    init() {
        // Initialize any required state
        loadWorkouts()
    }
    
    func loadWorkouts() {
        // TODO: Implement workout loading from persistence
    }
    
    func addWorkout(_ workout: WorkoutEntry) {
        workouts.insert(workout, at: 0)
        // TODO: Implement persistence
    }
} 