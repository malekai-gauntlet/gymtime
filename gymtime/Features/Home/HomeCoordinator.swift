// 📄 Coordinates navigation and flow within the home feature

import SwiftUI

struct HomeCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        HomeView(viewModel: viewModel)
    }
} 