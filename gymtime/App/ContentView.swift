// 📄 Main entry point of the app that sets up the root view structure

//
import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        if coordinator.isAuthenticated {
            HomeCoordinator()
        } else {
            AuthenticationView(viewModel: AuthenticationViewModel(coordinator: coordinator))
        }
    }
}
