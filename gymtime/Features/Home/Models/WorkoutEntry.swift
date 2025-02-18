// 📄 Defines the data structure for a workout entry

import Foundation

struct WorkoutEntry: Identifiable {
    let id: UUID
    var exercise: String
    var weight: Double?
    var sets: Int?
    var reps: Int?
    var notes: String?
    
    init(id: UUID = UUID(), exercise: String, weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, notes: String? = nil) {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.notes = notes
    }
}