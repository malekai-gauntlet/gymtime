// 📄 Service for parsing workout text into structured data

import Foundation
import Supabase

actor WorkoutParser {
    private let openAIService: OpenAIService
    private let supabase: SupabaseClient
    
    init(openAIService: OpenAIService, supabase: SupabaseClient) {
        self.openAIService = openAIService
        self.supabase = supabase
    }
    
    struct ParsedWorkout: Codable {
        var exercise: String
        var muscle_group: String
        var duration: String?
        var weight: String?
        var sets: Int?
        var reps: Int?
        var notes: String?
    }
    
    func parse(text: String, date: Date = Date()) async throws -> [WorkoutEntry] {
        // Get JSON response from OpenAI
        let jsonString = try await openAIService.generateCompletion(prompt: text)
        
        // Parse JSON into our struct array
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ParserError.invalidData
        }
        
        let parsedWorkouts = try JSONDecoder().decode([ParsedWorkout].self, from: jsonData)
        
        // Get current user ID
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ParserError.noUserId
        }
        
        // Clean and validate each workout
        return try parsedWorkouts.map { try cleanAndValidate($0, userId: userId, date: date) }
    }
    
    private func cleanAndValidate(_ parsed: ParsedWorkout, userId: UUID, date: Date) throws -> WorkoutEntry {
        // Clean exercise name
        let exercise = cleanExerciseName(parsed.exercise)
        guard !exercise.isEmpty else {
            throw ParserError.missingExercise
        }
        
        // Clean muscle group
        let muscleGroup = parsed.muscle_group.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !muscleGroup.isEmpty else {
            throw ParserError.missingMuscleGroup
        }
        
        // Clean weight (if present)
        let weight = parsed.weight.flatMap { cleanWeight($0) }
        
        // Clean duration (if present)
        let duration = parsed.duration?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Combine any notes with duration for context
        var notes = parsed.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let duration = duration {
            if !notes.isEmpty {
                notes = "\(duration) - \(notes)"
            } else {
                notes = duration
            }
        }
        
        return WorkoutEntry(
            userId: userId,
            exercise: exercise,
            muscleGroup: muscleGroup,
            weight: weight,
            sets: parsed.sets,
            reps: parsed.reps,
            notes: notes.isEmpty ? nil : notes,
            date: date
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
    
    func summarizeWorkout(text: String) async throws -> String {
        // Get response from OpenAI
        let response = try await openAIService.generateSummary(prompt: text)
        
        // Clean up any quotes or extra whitespace
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    enum ParserError: Error {
        case invalidData
        case missingExercise
        case missingMuscleGroup
        case invalidFormat
        case noUserId
    }
} 