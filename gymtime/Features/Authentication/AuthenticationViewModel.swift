// 📄 Manages authentication state and handles login/signup logic

import Foundation
import SwiftUI
import Supabase

// Enum to track which authentication screen to display
enum AuthenticationFlow {
    case login
    case signup
}

// Authentication-specific errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case emailInUse
    case invalidEmail
    case weakPassword
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Unable to connect. Please check your internet connection"
        case .emailInUse:
            return "This email is already in use"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .unknownError(let message):
            return message
        }
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    // Published properties to track the current state
    @Published var flow: AuthenticationFlow = .login
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: AuthError?
    
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    // Sign in with email and password
    func signIn() async {
        isLoading = true
        error = nil
        
        do {
            // Attempt to sign in using Supabase auth
            try await supabase.auth.signIn(
                email: email,
                password: password
            )
            // If successful, tell the coordinator to update app state
            coordinator.signIn()
        } catch {
            // Map Supabase errors to our custom AuthError type
            if let authError = error as? AuthError {
                self.error = authError
            } else {
                self.error = .unknownError(error.localizedDescription)
            }
        }
        
        isLoading = false
    }
    
    // Sign up with email and password
    func signUp() async {
        isLoading = true
        error = nil
        
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            error = .invalidCredentials
            isLoading = false
            return
        }
        
        do {
            // Attempt to create a new user with Supabase auth
            // We don't need to manually create a profile because our database trigger handles that
            try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // If successful, sign in the user
            coordinator.signIn()
        } catch let error as AuthError {
            self.error = error
        } catch {
            // Handle specific Supabase error cases
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("email") && errorDescription.contains("taken") {
                self.error = .emailInUse
            } else if errorDescription.contains("password") {
                self.error = .weakPassword
            } else if errorDescription.contains("email") && errorDescription.contains("invalid") {
                self.error = .invalidEmail
            } else {
                self.error = .unknownError(error.localizedDescription)
            }
        }
        
        isLoading = false
    }
    
    // Function to switch between login and signup
    func switchFlow() {
        flow = flow == .login ? .signup : .login
        // Clear the fields and errors when switching
        email = ""
        password = ""
        error = nil
    }
    
    // Function to handle anonymous sign-in
    func signInAnonymously() async {
        isLoading = true
        error = nil
        
        do {
            // Attempt anonymous sign in using Supabase auth
            try await supabase.auth.signInAnonymously()
            // If successful, tell the coordinator to update app state
            coordinator.signIn()
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // Function to handle logout
    func signOut() async {
        isLoading = true
        error = nil
        
        do {
            try await supabase.auth.signOut()
            coordinator.signOut()
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
}
