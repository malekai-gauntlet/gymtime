// 📄 Visualizes audio input levels as an animated waveform

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    
    private let numberOfBars = 30
    private let spacing: CGFloat = 4
    private let minBarHeight: CGFloat = 3
    private let maxBarHeight: CGFloat = 50
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gymtimeAccent)
                    .frame(width: 3, height: barHeight)
                    .animation(.easeOut(duration: 0.2), value: audioLevel)
            }
        }
        .frame(height: maxBarHeight)
    }
    
    private var barHeight: CGFloat {
        let height = CGFloat(audioLevel) * maxBarHeight
        return max(height, minBarHeight)
    }
} 