// 📄 Provides the signup form interface with email and password fields
import SwiftUI

struct SignUpView: View {
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
            
            // Sign Up button
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Switch to login
            Button("Already have an account? Log In") {
                viewModel.switchFlow()
            }
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}
