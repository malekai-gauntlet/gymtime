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
                
                PTView()
                    .tag(1)
                
                FeedView()  // Replace placeholder with actual FeedView
                    .tag(2)
                
                Color.gymtimeBackground  // Placeholder for Profile
                    .tag(3)
            }
            .tabViewStyle(.automatic)
            
            BottomNavBarView(selectedTab: $selectedTab)
        }
    }
} 