// 📄 Individual navigation bar item with icon and text

import SwiftUI

struct NavBarItem: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 10))
        }
        .foregroundColor(isSelected ? .gymtimeAccent : .gymtimeTextSecondary)
        .frame(maxWidth: .infinity)
    }
} 