// 📄 Visualizes audio levels during recording with an animated waveform

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    
    // Constants for waveform appearance
    private let numberOfBars = 30
    private let spacing: CGFloat = 4
    private let minBarHeight: CGFloat = 3
    private let maxBarHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 2
    
    // Ensure a minimum visible bar height even with zero audio level
    private var effectiveAudioLevel: Float {
        return max(0.05, audioLevel) // Ensure at least 5% height for visibility
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                // Calculate height based on audio level and add randomness for visual effect
                let randomFactor = Double.random(in: 0.8...1.2)
                let height = max(
                    minBarHeight,
                    CGFloat(effectiveAudioLevel) * maxBarHeight * CGFloat(randomFactor)
                )
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gymtimeAccent)
                    .frame(width: 3, height: height)
                    // Remove all animation for instant appearance
                    // .animation(
                    //    .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                    //    value: height
                    // )
            }
        }
        .frame(height: maxBarHeight)
    }
}

#Preview {
    WaveformView(audioLevel: 0.5)
        .padding()
        .background(Color.black)
}
