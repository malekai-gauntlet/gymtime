// 📄 Coordinates navigation and flow within the home feature

import SwiftUI

struct HomeCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: viewModel)
                    .tag(0)
                
                PTView(viewModel: PTViewModel(homeViewModel: viewModel), selectedTab: $selectedTab)
                    .tag(1)
                
                FeedView()
                    .tag(2)
                
                ProfileCoordinator()  // Use ProfileCoordinator instead of ProfileView
                    .tag(3)
            }
            .tabViewStyle(.automatic)
            
            BottomNavBarView(selectedTab: $selectedTab)
        }
    }
} 