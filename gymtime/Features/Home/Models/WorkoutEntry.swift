// 📄 Defines the data structure for a workout entry

import Foundation

struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var exercise: String
    var muscleGroup: String?
    var weight: Double?
    var sets: Int?
    var reps: Int?
    var notes: String?
    var date: Date
    var location: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exercise
        case muscleGroup = "muscle_group"
        case weight
        case sets
        case reps
        case notes
        case date
        case location
    }
    
    init(id: UUID = UUID(), userId: UUID, exercise: String, muscleGroup: String? = nil, weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, notes: String? = nil, date: Date = Date(), location: String? = nil) {
        self.id = id
        self.userId = userId
        self.exercise = exercise
        self.muscleGroup = muscleGroup
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.date = Calendar.current.startOfDay(for: date)  // Ensure we only store the date part
        self.location = location  // Initialize location
    }
    
    // Custom encoding/decoding for date to match Supabase format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        exercise = try container.decode(String.self, forKey: .exercise)
        muscleGroup = try container.decodeIfPresent(String.self, forKey: .muscleGroup)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Decode date with timezone information
        let dateString = try container.decode(String.self, forKey: .date)
        
        // Create a date formatter for date-only format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        if let parsedDate = formatter.date(from: dateString) {
            // Set to start of day in local timezone
            date = Calendar.current.startOfDay(for: parsedDate)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Date string does not match expected format: \(dateString)"
            ))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(exercise, forKey: .exercise)
        try container.encodeIfPresent(muscleGroup, forKey: .muscleGroup)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(sets, forKey: .sets)
        try container.encodeIfPresent(reps, forKey: .reps)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(location, forKey: .location)
        
        // Encode date in ISO8601 format (date only)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: date)
        try container.encode(dateString, forKey: .date)
    }
}