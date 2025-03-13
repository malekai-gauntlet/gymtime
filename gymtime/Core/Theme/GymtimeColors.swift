// 📄 Defines the app's color theme and provides easy access to colors

import SwiftUI

extension Color {
    struct Gymtime {
        static let background = Color("Background", bundle: .main)
        static let accentPrimary = Color("AccentPrimary", bundle: .main)
        static let textPrimary = Color("TextPrimary", bundle: .main)
        static let textSecondary = Color("TextSecondary", bundle: .main)
    }
    
    static var gymtimeBackground: Color { Gymtime.background }
    static var gymtimeAccent: Color { Gymtime.accentPrimary }
    static var gymtimeText: Color { Gymtime.textPrimary }
    static var gymtimeTextSecondary: Color { Gymtime.textSecondary }
} 