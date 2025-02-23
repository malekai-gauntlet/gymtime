// 📄 Voice recording extensions for HomeViewModel

import Foundation
import SwiftUI

extension HomeViewModel {
    // MARK: - Voice Recording Management
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
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
                
                let entries = try await workoutParser.parse(text: transcript)
                
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
                    self.error = "Failed to process recording: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
} 