// 📄 Manages authentication state and handles login/signup logic

import Foundation
import SwiftUI

// Enum to track which authentication screen to display
enum AuthenticationFlow {
    case login
    case signup
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    // Published properties to track the current state
    @Published var flow: AuthenticationFlow = .login
    @Published var email: String = ""
    @Published var password: String = ""
    
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    // Placeholder functions for authentication (will be implemented later)
    func signIn() async {
        // Will implement actual sign in logic later
        print("Sign in attempted with email: \(email)")
        coordinator.signIn()
    }
    
    func signUp() async {
        // Will implement actual sign up logic later
        print("Sign up attempted with email: \(email)")
        coordinator.signIn()
    }
    
    // Function to switch between login and signup
    func switchFlow() {
        flow = flow == .login ? .signup : .login
        // Clear the fields when switching
        email = ""
        password = ""
    }
}
