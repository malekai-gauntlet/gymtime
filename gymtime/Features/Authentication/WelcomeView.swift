import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showAuthenticationView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // App logo/title area
                Text("gymhead")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Log workouts faster with Voice AI")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Continue with Email button
                NavigationLink(destination: AuthenticationView(viewModel: viewModel), isActive: $showAuthenticationView) {
                    HStack {
                        Spacer()
                        Image(systemName: "envelope")
                            .foregroundColor(.black)
                        Text("Continue with E-mail")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Skip Signup button
                Button(action: {
                    Task {
                        await viewModel.signInAnonymously()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "forward.fill")
                        Text("Skip Signup")
                            .font(.headline)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
} 