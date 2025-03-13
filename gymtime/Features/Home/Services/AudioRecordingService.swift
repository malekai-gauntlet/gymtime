// 📄 Service for handling audio recording and level monitoring

import Foundation
import AVFoundation
import Combine

class AudioRecordingService: ObservableObject {
    // Published properties for UI updates
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
    // Audio session and recorder
    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    
    // Timer for monitoring audio levels
    private var levelTimer: Timer?
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        guard let audioSession = audioSession else { return }
        
        // Set an initial audio level value immediately so the waveform appears
        DispatchQueue.main.async {
            self.audioLevel = 0.05 // Small non-zero value for initial waveform display
        }
        
        // Create the audio file URL in tmp directory
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        // Audio recording settings
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Request permission to record
            try audioSession.setActive(true)
            
            // Create and configure the recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // Start recording
            audioRecorder?.record()
            isRecording = true
            
            // Start monitoring audio levels
            startMonitoringAudioLevels()
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopMonitoringAudioLevels()
    }
    
    private func startMonitoringAudioLevels() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.audioRecorder?.updateMeters()
            let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            
            // Enhanced normalization for better sensitivity
            // Adjust range from -160...0 to 0...1 with enhanced sensitivity for speech
            let minDb: Float = -60  // Focus on speech-relevant range
            let normalizedLevel = max(0.0, min(1.0, (level - minDb) / abs(minDb)))
            let enhancedLevel = pow(normalizedLevel, 0.5)  // Square root to enhance lower levels
            
            DispatchQueue.main.async {
                self.audioLevel = enhancedLevel
            }
        }
    }
    
    private func stopMonitoringAudioLevels() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    deinit {
        stopRecording()
        try? audioSession?.setActive(false)
    }
} 