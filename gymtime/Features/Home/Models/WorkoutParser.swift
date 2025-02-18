// 📄 Service for parsing workout text into structured data

import Foundation

actor WorkoutParser {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    struct ParsedWorkout: Codable {
        var exercise: String
        var weight: String?
        var sets: Int?
        var reps: Int?
        var notes: String?
    }
    
    func parse(text: String) async throws -> WorkoutEntry {
        // Get JSON response from OpenAI
        let jsonString = try await openAIService.generateCompletion(prompt: text)
        
        // Parse JSON into our struct
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ParserError.invalidData
        }
        
        let parsedWorkout = try JSONDecoder().decode(ParsedWorkout.self, from: jsonData)
        
        // Clean and validate the data
        return try cleanAndValidate(parsedWorkout)
    }
    
    private func cleanAndValidate(_ parsed: ParsedWorkout) throws -> WorkoutEntry {
        // Clean exercise name
        let exercise = cleanExerciseName(parsed.exercise)
        guard !exercise.isEmpty else {
            throw ParserError.missingExercise
        }
        
        // Clean weight (if present)
        let weight = parsed.weight.flatMap { cleanWeight($0) }
        
        return WorkoutEntry(
            id: UUID(),
            exercise: exercise,
            weight: weight,
            sets: parsed.sets,
            reps: parsed.reps,
            notes: parsed.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    private func cleanExerciseName(_ name: String) -> String {
        // Capitalize each word and clean whitespace
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    private func cleanWeight(_ weight: String) -> Double? {
        // Extract numbers and standardize format
        let numbers = weight.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        
        return Double(numbers)
    }
    
    enum ParserError: Error {
        case invalidData
        case missingExercise
        case invalidFormat
    }
} 