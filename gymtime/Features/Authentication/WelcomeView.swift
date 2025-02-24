import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showAuthenticationView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // App logo/title area
                Image("weight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
                    .padding(.bottom)
                    .background(Color.clear) // Adding this temporarily to debug
                
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