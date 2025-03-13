// 📄 Simple tooltip overlay modifier for onboarding tooltips (no arrow version)

import SwiftUI

/// A view modifier that adds a simple tooltip overlay with a dimmed background
struct SimpleTooltipOverlay: ViewModifier {
    let isVisible: Bool
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isVisible {
                // Dimmed background
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                    .transition(.opacity)
                
                // Tooltip bubble
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

extension View {
    func simpleTooltip(
        isVisible: Bool,
        title: String,
        message: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(SimpleTooltipOverlay(
            isVisible: isVisible,
            title: title,
            message: message,
            onDismiss: onDismiss
        ))
    }
} 