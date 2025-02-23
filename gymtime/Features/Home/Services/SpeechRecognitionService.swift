// 📄 Service for handling speech recognition and transcription

import Foundation
import Speech
import Combine
import AVFAudio

class SpeechRecognitionService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isAuthorized: Bool = false
    @Published var error: String?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    
    init() {
        // Initialize with user's locale or fallback to US English
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkPermissions()
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                case .denied:
                    self?.error = "Speech recognition permission was denied"
                case .restricted:
                    self?.error = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self?.error = "Speech recognition permission not determined"
                @unknown default:
                    self?.error = "Unknown authorization status"
                }
            }
        }
    }
    
    func startRecording() {
        // Reset state
        transcript = ""
        error = nil
        
        // Validate authorization
        guard isAuthorized else {
            error = "Speech recognition not authorized"
            return
        }
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            error = "Speech recognition not available"
            return
        }
        
        // Check audio permission
        let audioSession = AVAudioSession.sharedInstance()
        guard audioSession.recordPermission == AVAudioSession.RecordPermission.granted else {
            error = "Microphone permission not granted"
            return
        }
        
        // Set up audio engine and recognition request
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                // Ignore cancellation errors as they're expected
                if error.domain == "kAFAssistantErrorDomain" && error.code == 203 {
                    return
                }
                self.error = error.localizedDescription
                self.stopRecording()
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
        }
        
        // Install tap and start audio engine
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            self.error = "Could not start audio engine: \(error.localizedDescription)"
            return
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        // Clear any error when stopping normally
        error = nil
    }
    
    deinit {
        stopRecording()
    }
} 