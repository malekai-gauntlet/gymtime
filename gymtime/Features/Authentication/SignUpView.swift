// 📄 Provides the signup form interface with email and password fields
import SwiftUI

struct SignUpView: View {
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
                .disabled(viewModel.isLoading)
            
            // Password field
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .textContentType(.password)
                .foregroundColor(.gymtimeText)
                .disabled(viewModel.isLoading)
            
            // Error message
            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Sign Up button
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign Up")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gymtimeAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(viewModel.isLoading)
            
            // Switch to login
            Button("Already have an account? Log In") {
                viewModel.switchFlow()
            }
            .foregroundColor(.gymtimeAccent)
            .font(.subheadline)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal)
    }
}
