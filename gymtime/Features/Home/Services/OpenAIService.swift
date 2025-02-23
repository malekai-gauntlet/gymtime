// 📄 Service for handling OpenAI API interactions

import Foundation

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    enum OpenAIError: Error {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
    }
    
    struct ChatCompletionResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
        }
        
        struct Message: Codable {
            let content: String
        }
    }
    
    func generateCompletion(prompt: String) async throws -> String {
        return try await makeRequest(
            prompt: prompt,
            model: "gpt-3.5-turbo",
            systemPrompt: """
            You are a fitness tracking assistant. Parse the workout description into one or more exercises.
            Return a JSON array where each exercise contains:
            - exercise: (required) name of the exercise
            - duration: time spent (e.g. '10 minutes', '30 seconds')
            - weight: any weight/resistance used
            - sets: number of sets
            - reps: reps per set
            - notes: any additional details or context

            Return as a JSON array even for single exercises. Examples:
            "10 minutes of abs" → [{"exercise": "Ab Workout", "duration": "10 mins"}]
            "Bench press 185lbs 3x5" → [{"exercise": "Bench Press", "weight": "185", "sets": 3, "reps": 5}]
            """
        )
    }
    
    func generateSummary(prompt: String) async throws -> String {
        return try await makeRequest(
            prompt: prompt,
            model: "gpt-4",
            systemPrompt: """
            You are a fitness tracking assistant that creates concise, natural workout summaries.
            Summarize the workout in 3-4 words using common fitness terminology.
            Focus on the main muscle groups or workout type.
            Use "+" to combine different focuses.
            DO NOT return JSON formatting or quotes.

            Examples:
            - "Upper Body + Core"
            - "Full Body Circuit"
            - "Legs + Cardio"
            - "Push Day"
            - "Back & Biceps"
            """
        )
    }
    
    private func makeRequest(prompt: String, model: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request body
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Make the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenAIError.apiError(errorMessage)
            }
            
            let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            return completionResponse.choices.first?.message.content ?? ""
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
} 