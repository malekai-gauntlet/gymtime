func generateSummary(prompt: String) async throws -> String {
    return try await makeRequest(
        prompt: prompt,
        // OpenAI model (commented out)
        // model: "gpt-4",
        
        // Using faster model with higher rate limits
        model: "llama-3.1-8b-instant",
        systemPrompt: """
// ... existing code ... 