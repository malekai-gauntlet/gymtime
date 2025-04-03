import SwiftUI

struct TimerView: View {
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    
    var formattedTime: String {
        let minutes = Int(timeElapsed / 60)
        let seconds = Int(timeElapsed) % 60
        let hundredths = Int((timeElapsed * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
    
    var body: some View {
        ZStack {
            Color.gymtimeBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 50) {
                Spacer()
                
                // Timer Display
                Text(formattedTime)
                    .font(.system(size: 70, weight: .regular, design: .monospaced))
                    .foregroundColor(.gymtimeText)
                    .monospacedDigit()
                    .tracking(0.5)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Reset Button
                    Button(action: {
                        stopTimer()
                        timeElapsed = 0
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 20))
                            Text("Reset")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.gymtimeText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Start/Stop Button
                    Button(action: {
                        if isRunning {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 20))
                            Text(isRunning ? "Stop Timer" : "Start Timer")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gymtimeAccent)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
} 