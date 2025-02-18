// 📄 Provides the login form interface with email and password fields
import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            // Password field
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            // Login button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Switch to signup
            Button("Don't have an account? Sign Up") {
                viewModel.switchFlow()
            }
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}
