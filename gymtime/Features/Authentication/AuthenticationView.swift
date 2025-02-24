// 📄 Main container view that switches between login and signup screens

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
            } else {
                SignUpView(viewModel: viewModel)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .imageScale(.large)
        })
    }
}
