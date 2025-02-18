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
            let normalizedLevel = pow(10, level / 20)
            
            DispatchQueue.main.async {
                self.audioLevel = normalizedLevel
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