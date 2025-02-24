// 📄 Coordinates navigation and flow within the home feature

import SwiftUI
import Supabase

struct HomeCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: viewModel)
                    .tag(0)
                
                WeightsCoordinator(supabase: supabase)
                    .tag(1)
                
                PTView(viewModel: PTViewModel(homeViewModel: viewModel), selectedTab: $selectedTab)
                    .tag(2)
                
                FeedView()
                    .tag(3)
                
                ProfileCoordinator()  // Use ProfileCoordinator instead of ProfileView
                    .tag(4)
            }
            .tabViewStyle(.automatic)
            
            BottomNavBarView(selectedTab: $selectedTab)
        }
    }
} 