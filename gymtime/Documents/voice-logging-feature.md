# Voice Logging Feature Implementation Plan

## Overview
Implement voice-based workout logging directly in the HomeView, allowing users to record their workouts through natural speech with a responsive UI and immediate transcription.

## Technical Components
1. **Audio Recording** ✅
   - ~~Implement audio recording using AVFoundation~~ ✅
   - ~~Add necessary microphone permissions~~ ✅
   - ~~Create audio session management~~ ✅
   - ~~Implement audio level monitoring for waveform visualization~~ ✅

2. **Speech Recognition** ✅
   - ~~Integrate Apple's Speech Recognition framework~~ ✅
   - ~~Add required permissions~~ ✅
   - ~~Implement real-time transcription~~ ✅
   - ~~Handle continuous recognition mode~~ ✅

3. **UI Components** 🔄
   - ~~Add recording button to HomeView with animation states:~~ ✅
     - ~~Idle state (microphone icon)~~ ✅
     - ~~Recording state (pulsing animation)~~ ✅
     - Processing state (loading spinner)
   - ~~Implement screen dimming overlay with tap-to-stop~~ ✅
   - ~~Create animated waveform visualization using audio levels~~ ✅
   - ~~Add live transcription display~~ ✅
   - Add processing indicator
   - ~~Implement haptic feedback for state changes~~ ✅

4. **Data Processing** ⏳
   - Parse transcribed text into workout data using OpenAI
   - Extract structured fields:
     - Exercise name
     - Weight
     - Sets
     - Reps
     - Notes
   - Handle natural language variations
   - Format data for storage
   - Implement data cleaning helpers:
     - Capitalize exercise names
     - Convert word numbers to digits
     - Handle units consistently

5. **State Management** 🔄
   - ~~Track recording states:~~ ✅
     - ~~Idle~~ ✅
     - ~~Recording~~ ✅
     - Processing
     - Error
   - ~~Manage audio session state~~ ✅
   - ~~Handle transcription state~~ ✅
   - Update workout list
   - Handle background/foreground transitions

## Implementation Steps

### Phase 1: Setup & Permissions ✅
1. ~~Add required permission keys to Info.plist:~~ ✅
   - ~~`NSMicrophoneUsageDescription`~~ ✅
   - ~~`NSSpeechRecognitionUsageDescription`~~ ✅
2. ~~Create AudioManager for handling recording and audio levels~~ ✅
3. ~~Create SpeechRecognitionManager~~ ✅
4. Set up OpenAI integration for parsing ⏳

### Phase 2: Core Recording Functionality ✅
1. ~~Implement basic audio recording with level monitoring~~ ✅
2. ~~Add speech recognition with continuous mode~~ ✅
3. ~~Create recording state management~~ ✅
4. ~~Add basic UI indicators~~ ✅
5. Implement OpenAI parsing integration ⏳

### Phase 3: UI Enhancement 🔄
1. ~~Implement screen dimming overlay with tap-to-stop~~ ✅
2. ~~Create waveform visualization using audio levels~~ ✅
3. ~~Add recording button animations:~~ ✅
   - ~~Idle microphone icon~~ ✅
   - ~~Recording pulse effect~~ ✅
   - Processing spinner
4. ~~Add live transcription display~~ ✅
5. ~~Implement haptic feedback~~ ✅
6. Add loading states and error handling UI

### Phase 4: Data Processing
1. Create workout text parser using OpenAI
2. Implement data cleaning helpers:
   - Word to number conversion
   - Text capitalization
   - Unit standardization
3. Add workout entry creation
4. Update workout table
5. Implement error handling and retries

### Phase 5: Polish & Testing
1. Add error handling with user feedback
2. Implement fallback mechanisms
3. Add loading states
4. Polish animations and transitions
5. Add user feedback:
   - Success toasts
   - Error messages
   - Processing indicators
6. Implement background mode handling
7. Add accessibility support

## Required Permissions ✅
```xml
<!-- Info.plist entries -->
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record your workout descriptions.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to convert your voice into workout entries.</string>
```

## Dependencies
- ~~AVFoundation~~ ✅
- Speech ⏳
- ~~SwiftUI~~ ✅
- ~~Combine~~ ✅
- OpenAI API (for natural language parsing)

## Data Model
```swift
struct WorkoutEntry {
    let id: UUID
    let date: Date
    var exercise: String
    var weight: String?
    var sets: Int?
    var reps: Int?
    var notes: String?
}
```

## Notes
- ~~Ensure smooth transition between states with proper cleanup~~ ✅
- Provide clear visual and haptic feedback for all user actions
- Handle background/foreground transitions gracefully
- Consider accessibility implications
- Plan for error cases and network issues
- ~~Implement proper cleanup of audio session~~ ✅
- Add retry mechanism for failed API calls
- Consider offline support for basic recording
- Implement proper error messages for each failure case
- Add data validation before storage

---

## Next Steps (Priority Order):
1. ~~Add waveform visualization for audio levels~~ ✅
2. ~~Implement Speech Recognition to convert audio to text~~ ✅
3. ~~Add screen dimming overlay with tap-to-stop functionality~~ ✅
4. Set up OpenAI integration for parsing the transcribed text ⏳

Now that we have a polished recording UI, the next major step is to implement the OpenAI integration to parse the transcribed text into structured workout data. This will involve:

1. Setting up OpenAI API integration
2. Creating a parser for the workout text
3. Implementing the data cleaning helpers
4. Adding the workout to the table

Would you like to proceed with the OpenAI integration? 