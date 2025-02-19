// 📄 Provides the login form interface with email and password fields
import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .foregroundColor(.gymtimeText)
            
            // Password field
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .textContentType(.password)
                .foregroundColor(.gymtimeText)
            
            // Login button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gymtimeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Switch to signup
            Button("Don't have an account? Sign Up") {
                viewModel.switchFlow()
            }
            .foregroundColor(.gymtimeAccent)
            .font(.subheadline)
        }
        .padding(.horizontal)
    }
}
