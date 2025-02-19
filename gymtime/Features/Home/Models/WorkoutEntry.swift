// 📄 Defines the data structure for a workout entry

import Foundation

struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var exercise: String
    var weight: Double?
    var sets: Int?
    var reps: Int?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exercise
        case weight
        case sets
        case reps
        case notes
    }
    
    init(id: UUID = UUID(), userId: UUID, exercise: String, weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.exercise = exercise
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.notes = notes
    }
}