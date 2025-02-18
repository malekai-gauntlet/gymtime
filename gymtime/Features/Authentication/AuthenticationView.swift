// 📄 Main container view that switches between login and signup screens

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App logo/title area
                Text("gymtime")
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
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
