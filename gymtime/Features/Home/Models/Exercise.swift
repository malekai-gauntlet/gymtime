// 📄 Defines the data structure for an exercise in the library

import Foundation

/// Model for data from the exercises table in Supabase
struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let muscleGroup: String
    let equipment: String?
    let description: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case muscleGroup = "muscle_group"
        case equipment
        case description
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), name: String, category: String, muscleGroup: String, equipment: String? = nil, description: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.description = description
        self.createdAt = createdAt
    }
    
    // Initialize from decoder (handles Supabase format)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        muscleGroup = try container.decode(String.self, forKey: .muscleGroup)
        equipment = try container.decodeIfPresent(String.self, forKey: .equipment)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Decode timestamp from Supabase
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            // Fallback to simpler ISO format without fractional seconds
            let simpleFormatter = ISO8601DateFormatter()
            createdAt = simpleFormatter.date(from: dateString) ?? Date()
        }
    }
    
    // Convert an Exercise to a WorkoutEntry
    func toWorkoutEntry(userId: UUID, date: Date = Date()) -> WorkoutEntry {
        return WorkoutEntry(
            id: UUID(), // Generate a new ID
            userId: userId,
            exercise: name,
            muscleGroup: muscleGroup,
            weight: nil,
            sets: nil,
            reps: nil,
            notes: nil,
            date: date
        )
    }
} 