// 📄 Model for storing daily workout summaries

import Foundation

struct DailyWorkoutSummary: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    var summary: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case summary
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, date: Date, summary: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)  // Ensure we only store the date part
        self.summary = summary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom decoder to handle Supabase date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode simple properties
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        
        // Handle the date field specifically
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Could not parse date string: \(dateString)")
        }
        
        // Handle timestamps with a more lenient approach
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = timestampFormatter.date(from: createdAtString) ?? Date()
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = timestampFormatter.date(from: updatedAtString) ?? Date()
    }
} 