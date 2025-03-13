import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showAuthenticationView = false
    
    // Animation state variables
    @State private var buttonText = "Skip Signup"
    @State private var isTransitioning = false
    @State private var scale: CGFloat = 1.0
    
    // Staggered animation opacity values for different UI elements
    @State private var logoOpacity: Double = 0.0 // Start invisible
    @State private var titleOpacity: Double = 0.0 // Start invisible
    @State private var subtitleOpacity: Double = 0.0 // Start invisible
    @State private var buttonOpacity: Double = 0.0 // Start invisible
    
    // Initial animation positions and scales
    @State private var logoScale: CGFloat = 0.9 // Logo starts smaller
    @State private var titleOffset: CGFloat = 20 // Title starts below final position
    @State private var subtitleOffset: CGFloat = 15 // Subtitle starts below final position
    @State private var buttonsOffset: CGFloat = 30 // Buttons start below final position
    
    // Exit animation offsets and scales
    @State private var logoExitOffset: CGFloat = 0
    @State private var titleExitOffset: CGFloat = 0
    @State private var buttonsExitOffset: CGFloat = 0
    
    // Animation control
    @State private var hasAppeared = false
    @State private var showLogoGlow = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Welcome animation content
                VStack(spacing: 20) {
                    Spacer()
                    
                    // App logo/title area
                    VStack(spacing: 8) {
                        // Logo with optional glow effect
                        ZStack {
                            // Glow effect
                            if showLogoGlow {
                                Image("weight")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 100)
                                    .blur(radius: 15)
                                    .opacity(0.7)
                                    .scaleEffect(1.2)
                            }
                            
                            // Main logo
                            Image("weight")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 100)
                                .padding(.bottom)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .offset(y: logoExitOffset)
                        
                        // App title
                        Text("gymhead")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .opacity(titleOpacity)
                            .offset(y: isTransitioning ? titleExitOffset : titleOffset)
                        
                        // Subtitle
                        Text("Log workouts faster with Voice AI")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .opacity(subtitleOpacity)
                            .offset(y: isTransitioning ? titleExitOffset : subtitleOffset)
                    }
                    
                    Spacer()
                    
                    // Buttons area
                    VStack(spacing: 16) {
                        // Continue with Email button
                        NavigationLink(
                            destination: AuthenticationView(viewModel: viewModel)
                                .onAppear {
                                    // Reset viewModel state when navigating to auth view
                                    viewModel.email = ""
                                    viewModel.password = ""
                                    viewModel.error = nil
                                },
                            isActive: $showAuthenticationView
                        ) {
                            EmptyView()
                        }
                        
                        Button(action: {
                            // Ensure any active keyboard is dismissed before navigation
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // Slight delay to ensure UI is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showAuthenticationView = true
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "envelope")
                                    .foregroundColor(.white)
                                Text("Continue with E-mail")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gymtimeAccent)
                            .cornerRadius(12)
                        }
                        
                        // Skip Signup button with enhanced transition
                        Button(action: {
                            // INSTANT FEEDBACK: Set text and state immediately without animation
                            // This happens synchronously on the main thread for immediate visual feedback
                            buttonText = "Let's go!"
                            isTransitioning = true
                            
                            // Animate button scale down slightly - executed immediately after state change
                            withAnimation(.spring(response: 0.15)) {
                                scale = 0.97 // Slight scale down for button press effect
                            }
                            
                            // Start the coordinated exit animation sequence
                            playExitAnimation()
                            
                            // Start authentication in the background immediately
                            Task {
                                await viewModel.signInAnonymously()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if isTransitioning {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "forward.fill")
                                }
                                Text(buttonText)
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(isTransitioning ? 0.25 : 0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(viewModel.isLoading || isTransitioning)
                        .scaleEffect(scale)
                    }
                    .opacity(buttonOpacity)
                    .offset(y: isTransitioning ? buttonsExitOffset : buttonsOffset)
                }
                .padding()
                .navigationBarHidden(true)
                
                // Fullscreen overlay that appears during exit transition
                if isTransitioning {
                    Color.black
                        .opacity(calculateOverlayOpacity())
                        .ignoresSafeArea()
                        .zIndex(10)
                }
            }
        }
        .onAppear {
            // Only play the welcome animation if the view hasn't appeared before
            if !hasAppeared {
                playWelcomeAnimation()
                hasAppeared = true
            }
            
            // Fix for keyboard layout issues
            UITextField.appearance().keyboardAppearance = .dark
        }
    }
    
    // MARK: - Welcome Animation Sequence
    
    private func playWelcomeAnimation() {
        // Phase 1: Initial logo appears with glow (0-0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.8)) {
                logoOpacity = 1.0
            }
            
            // Add a subtle pulsing effect to the logo
            withAnimation(.easeInOut(duration: 1.2).repeatCount(1, autoreverses: true)) {
                logoScale = 1.0
            }
        }
        
        // Phase 2: Brand introduction - title appears, glow transitions (0.8-1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6)) {
                titleOpacity = 1.0
                titleOffset = 0 // Move to final position
            }
            
            // Transition the glow effect away
            withAnimation(.easeOut(duration: 0.5)) {
                showLogoGlow = false
            }
        }
        
        // Phase 3: Value proposition - subtitle appears (1.5-2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0 // Move to final position
            }
        }
        
        // Phase 4: Call to action - buttons appear (2.0-2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                buttonOpacity = 1.0
                buttonsOffset = 0 // Move to final position
            }
        }
    }
    
    // MARK: - Exit Animation Sequence
    
    private func playExitAnimation() {
        // Phase 1: Move buttons down and fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                buttonsExitOffset = 60 // Move buttons down
                buttonOpacity = 0.0 // Fade out
                scale = 1.05 // Slight scale up effect
            }
        }
        
        // Phase 2: Float logo up and fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6)) {
                logoExitOffset = -40 // Move logo up
                logoOpacity = 0.0 // Fade out
                logoScale = 1.1 // Slightly expand while fading
            }
        }
        
        // Phase 3: Slide title and subtitle sideways
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.55)) {
                titleExitOffset = 60 // Move title to the right
                titleOpacity = 0.0 // Fade out
                subtitleOpacity = 0.0 // Fade out subtitle
            }
        }
    }
    
    // Helper function to calculate overlay opacity based on other elements
    private func calculateOverlayOpacity() -> Double {
        // Creates a smooth transition from 0 to 1 as other elements fade out
        let combinedOpacity = (logoOpacity + titleOpacity + subtitleOpacity + buttonOpacity) / 4.0
        return 1.0 - combinedOpacity
    }
    
    // Reset all animation states to initial values
    private func resetAnimationState() {
        isTransitioning = false
        logoOpacity = 1.0
        titleOpacity = 1.0
        subtitleOpacity = 1.0
        buttonOpacity = 1.0
        logoScale = 1.0
        titleOffset = 0
        subtitleOffset = 0
        buttonsOffset = 0
        logoExitOffset = 0
        titleExitOffset = 0
        buttonsExitOffset = 0
        scale = 1.0
        buttonText = "Skip Signup"
    }
}