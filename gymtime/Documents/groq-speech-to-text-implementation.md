# Implementing Groq Speech-to-Text

## Current Implementation
- Using Apple's SFSpeechRecognizer (on-device)
- Transcribes speech to text locally
- Feeds text to Groq for workout parsing
- Limited accuracy for specialized fitness terminology

## Benefits of Groq Speech-to-Text
- Higher accuracy, especially for fitness terminology
- Better handling of accents and speech patterns
- Faster processing for longer recordings
- Consistent with our use of Groq for text processing
- OpenAI-compatible API structure

## Implementation Steps

1. **Continue Using Existing AudioRecordingService**
   - Keep the current audio recording functionality
   - Ensure we have a valid audio file (m4a format)

2. **Create a New GroqSpeechService**
   - Implement a service that takes the recorded audio file
   - Sends it to Groq's speech-to-text API
   - Returns the transcript

3. **Replace Apple's SpeechRecognitionService**
   - Modify HomeViewModel to use GroqSpeechService instead
   - Update UI to reflect the new service

## API Details

### Groq Transcription Endpoint
```
https://api.groq.com/openai/v1/audio/transcriptions
```

### Required Model
```
whisper-large-v3-turbo
```

### Example Implementation
```swift
func transcribeAudio(fileURL: URL) async throws -> String {
    let fileName = fileURL.lastPathComponent
    
    guard let audioData = try? Data(contentsOf: fileURL) else {
        throw TranscriptionError.fileReadError
    }
    
    var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add the model parameter
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
    body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
    
    // Add the file
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
    body.append(audioData)
    body.append("\r\n".data(using: .utf8)!)
    
    // Close the boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
    
    return response.text
}
```

## Notes
- Keep both implementations available for easy switching and comparison
- Test with various workout descriptions to compare accuracy
- Monitor API usage costs
- Optimize audio file size for faster upload/processing 