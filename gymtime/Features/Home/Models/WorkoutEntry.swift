// 📄 Defines the data structure for a workout entry

import Foundation

struct WorkoutEntry: Codable, Identifiable {
    let id: UUID
    let exercise: String
    let weight: Double?
    let sets: Int?
    let reps: Int?
    let notes: String?
    
    init(id: UUID = UUID(), exercise: String, weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, notes: String? = nil) {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.notes = notes
    }
}