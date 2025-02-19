// 📄 Visualizes audio input levels as an animated waveform

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    
    // Increased number of bars and adjusted spacing
    private let numberOfBars = 40
    private let spacing: CGFloat = 3
    private let minBarHeight: CGFloat = 4
    private let maxBarHeight: CGFloat = 80  // Increased maximum height
    private let barWidth: CGFloat = 4       // Slightly thicker bars
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth/2)
                    .fill(Color.gymtimeAccent)
                    .frame(width: barWidth, height: dynamicBarHeight(for: index))
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                        value: audioLevel
                    )
            }
        }
        .frame(height: maxBarHeight)
    }
    
    private func dynamicBarHeight(for index: Int) -> CGFloat {
        // Create a more dynamic wave pattern
        let centerOffset = abs(Float(index) - Float(numberOfBars)/2)
        let positionFactor = 1.0 - (centerOffset / Float(numberOfBars)) * 0.5
        
        // Apply a more sensitive transformation to the audio level
        let transformedLevel = pow(audioLevel, 0.7) // Makes lower levels more visible
        let height = CGFloat(transformedLevel * positionFactor) * maxBarHeight
        
        return max(height, minBarHeight)
    }
} 