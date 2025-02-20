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
} 