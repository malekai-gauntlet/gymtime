// 📄 Tooltip overlay modifier for onboarding tooltips

import SwiftUI

/// A view modifier that adds a tooltip overlay with a dimmed background
struct TooltipOverlay: ViewModifier {
    let isVisible: Bool
    let title: String
    let message: String
    let arrowOffset: CGPoint
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
                
                // Tooltip bubble with arrow
                VStack(spacing: 8) {
                    // Content
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
                    
                    // Arrow at bottom
                    Triangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 10)
                        .offset(x: arrowOffset.x, y: 0)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .offset(x: arrowOffset.x, y: arrowOffset.y)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

/// Triangle shape for the tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

extension View {
    func tooltip(
        isVisible: Bool,
        title: String,
        message: String,
        arrowOffset: CGPoint = .zero,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(TooltipOverlay(
            isVisible: isVisible,
            title: title,
            message: message,
            arrowOffset: arrowOffset,
            onDismiss: onDismiss
        ))
    }
} 