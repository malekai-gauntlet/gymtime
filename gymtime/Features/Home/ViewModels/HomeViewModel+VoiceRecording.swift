// 📄 Voice recording extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Voice Recording Management
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            // Update UI state IMMEDIATELY
            isRecording = true
            transcript = ""
            error = nil
            isProcessing = false
            audioLevel = 0.5  // Keep at 0.5 as requested
            
            // Defer audio setup to happen AFTER UI updates
            Task { @MainActor in
                // Give UI time to update - reduced from 10ms to 1ms for faster response
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms pause
                startRecordingServices()
            }
        }
    }
    
    private func startRecordingServices() {
        print("🎤 Starting voice recording")
        // Start both services
        audioRecordingService.startRecording()
        speechRecognitionService.startRecording()
    }
    
    private func startRecording() {
        // This method is kept for backward compatibility but isn't used directly anymore
        isRecording = true
        print("🎤 Starting voice recording")
        
        // Reset state
        transcript = ""
        error = nil
        isProcessing = false
        
        // Start both services
        audioRecordingService.startRecording()
        speechRecognitionService.startRecording()
    }
    
    private func stopRecording() {
        print("⏹️ Stopping voice recording")
        isProcessing = true
        
        // Stop both services
        audioRecordingService.stopRecording()
        speechRecognitionService.stopRecording()
        
        // Process the transcript
        Task {
            do {
                print("📝 Processing transcript: \(transcript)")
                
                // Check if transcript is empty or just whitespace
                guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    // No audio detected, just silently finish without error
                    await MainActor.run {
                        isProcessing = false
                        transcript = ""
                    }
                    return
                }
                
                // Use the selected date from calendar state
                let entries = try await workoutParser.parse(text: transcript, date: calendarState.selectedDate)
                
                // Add workouts in reverse for correct order
                for entry in entries {
                    addWorkout(entry)
                }
                
                // Reset UI state
                await MainActor.run {
                    isProcessing = false
                    transcript = ""
                }
                
            } catch {
                print("❌ Failed to process voice recording: \(error)")
                await MainActor.run {
                    // Convert technical error to a fun, user-friendly message
                    self.error = getFriendlyErrorMessage(from: error)
                    isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Fun Error Messages
    
    private func getFriendlyErrorMessage(from error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        // JSON parsing errors
        if errorString.contains("json") || errorString.contains("format") || errorString.contains("decode") {
            return "🏋️‍♂️ That's quite the workout and it confused our AI. Try again with clearer details."
        }
        
        // No exercise detected
        if errorString.contains("missingexercise") {
            return "🤔 Hmm, couldn't detect any exercises. What workout did you do?"
        }
        
        // Network errors
        if errorString.contains("network") || errorString.contains("internet") || errorString.contains("connection") {
            return "📡 Gym wifi acting up again? Check your connection."
        }
        
        // Model errors
        if errorString.contains("model") {
            return "🤖 The AI is catching its breath and needs a spot. Try again in a moment."
        }
        
        // API errors
        if errorString.contains("api") {
            return "⚡ Back in the gym already? The AI and the weights need a rest day."
        }
        
        // Default fun message for any other errors
        return "💪 Even workouts have off days! Try recording again."
    }
} 