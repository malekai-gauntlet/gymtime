import Foundation

/// Model for data from the workout_profiles view in Supabase
/// This view joins workout data with user profile information
struct WorkoutProfileEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let exercise: String
    let muscleGroup: String?
    let weight: Double?
    let sets: Int?
    let reps: Int?
    let notes: String?
    let date: Date
    let username: String
    let fullName: String?
    
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
        case username
        case fullName = "full_name"
    }
    
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
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        
        // Date decoding logic (same as WorkoutEntry)
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        if let parsedDate = formatter.date(from: dateString) {
            date = Calendar.current.startOfDay(for: parsedDate)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Date string does not match expected format: \(dateString)"
            ))
        }
    }
} 