// 📄 Main coordinator that handles app-level navigation and state

import SwiftUI

class AppCoordinator: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    func signIn() {
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
    }
} 