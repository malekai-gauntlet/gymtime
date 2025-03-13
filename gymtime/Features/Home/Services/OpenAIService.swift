// 📄 Service for handling OpenAI API interactions

import Foundation

class OpenAIService {
    private let apiKey: String
    // OpenAI endpoint (commented out)
    // private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // Groq endpoint (OpenAI-compatible)
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    
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
            // OpenAI model (commented out)
            // model: "gpt-3.5-turbo",
            
            // Groq model - Llama 3.1 for fast processing
            model: "llama-3.1-8b-instant",
            systemPrompt: """
            You are a fitness tracking assistant. Parse the workout description into one or more exercises.
            
            IMPORTANT: Return a valid JSON array that strictly follows this format:
            ```json
            [
              {
                "exercise": "Exercise Name",
                "muscle_group": "Primary Muscle Group",
                "duration": "Time spent (optional)",
                "weight": "Weight used (optional)",
                "sets": integer_value_not_string,
                "reps": integer_value_not_string,
                "notes": "Additional details (optional)"
              }
            ]
            ```
            
            Field requirements:
            - exercise: (REQUIRED) Name of the exercise as a string
            - muscle_group: (REQUIRED) One of: Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Cardio
            - duration: (OPTIONAL) Time spent as a string (e.g. "10 minutes", "30 seconds")
            - weight: (OPTIONAL) Weight/resistance used as a string (e.g. "185 lbs", "50 kg")
            - sets: (OPTIONAL) Number of sets as an INTEGER (not a string)
            - reps: (OPTIONAL) Reps per set as an INTEGER (not a string)
            - notes: (OPTIONAL) Additional details as a string, include ALL extra details mentioned.
            
            Rules for JSON formatting:
            1. Always use double quotes for strings, never single quotes
            2. Include only fields that are mentioned or can be reasonably inferred
            3. For missing optional fields, omit them entirely (don't include null values)
            4. SETS and REPS must be integers without quotes (e.g., 3 not "3")
            5. Always return a well-formed JSON array, even for a single exercise
            
            Examples:
            
            Input: "10 minutes of abs"
            Output: [{"exercise": "Ab Workout", "muscle_group": "Core", "duration": "10 mins"}]
            
            Input: "Bench press 185lbs 3x5"
            Output: [{"exercise": "Bench Press", "muscle_group": "Chest", "weight": "185 lbs", "sets": 3, "reps": 5}]
            
            Input: "Tricep push downs, 4 sets of 10 reps, did 70 pounds for the warmup then 3 sets at 85 pounds, felt strong"
            Output: [{"exercise": "Tricep Pushdown", "muscle_group": "Triceps", "weight": "85 lbs", "sets": 4, "reps": 10, "notes": "70 pounds for warmup, then 3 sets at 85 pounds. Felt strong."}]
            
            Remember to ensure your response is valid JSON that can be parsed by a JSON decoder. Never include backticks, markdown formatting, or explanatory text.
            """
        )
    }
    
    func generateSummary(prompt: String) async throws -> String {
        return try await makeRequest(
            prompt: prompt,
            // OpenAI model (commented out)
            // model: "gpt-4",
            
            // Groq model - using the larger model for better summaries
            model: "llama-3.1-8b-instant",
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