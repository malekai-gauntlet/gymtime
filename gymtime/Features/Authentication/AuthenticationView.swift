// 📄 Main container view that switches between login and signup screens

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App logo/title area
                Text("gymhead")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Log workouts faster with Voice AI")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Show either login or signup view based on current flow
                if viewModel.flow == .login {
                    LoginView(viewModel: viewModel)
                } else {
                    SignUpView(viewModel: viewModel)
                }
                
                // Skip Signup button
                Button(action: {
                    Task {
                        await viewModel.signInAnonymously()
                    }
                }) {
                    Text("Skip Signup")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 4)
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
