// 📄 Main container view that switches between login and signup screens

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var viewTransition = false
    
    var body: some View {
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
                    .transition(.opacity)
                    .id("login-view") // Add stable ID for transitions
            } else {
                SignUpView(viewModel: viewModel)
                    .transition(.opacity)
                    .id("signup-view") // Add stable ID for transitions
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: viewModel.flow)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            // Dismiss keyboard before navigating back
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // Add a small delay before dismissing to ensure keyboard is dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .imageScale(.large)
        })
        .onAppear {
            // Fix for keyboard layout issues
            UITextField.appearance().keyboardAppearance = .dark
        }
    }
}
