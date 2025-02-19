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
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exercise
        case weight
        case sets
        case reps
        case notes
        case date
    }
    
    init(id: UUID = UUID(), userId: UUID, exercise: String, weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, notes: String? = nil, date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.exercise = exercise
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.date = Calendar.current.startOfDay(for: date)  // Ensure we only store the date part
    }
    
    // Custom encoding/decoding for date to match Supabase format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        exercise = try container.decode(String.self, forKey: .exercise)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Decode date with timezone information
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime] // Include timezone info
        
        if let parsedDate = formatter.date(from: dateString) {
            // Convert UTC to local time zone's start of day
            let localDate = Calendar.current.date(byAdding: .second, value: TimeZone.current.secondsFromGMT(), to: parsedDate) ?? parsedDate
            date = Calendar.current.startOfDay(for: localDate)
        } else {
            date = Calendar.current.startOfDay(for: Date())
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(exercise, forKey: .exercise)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(sets, forKey: .sets)
        try container.encodeIfPresent(reps, forKey: .reps)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        // Encode date in ISO8601 format (date only)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: date)
        try container.encode(dateString, forKey: .date)
    }
}