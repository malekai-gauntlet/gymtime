// 📄 Coordinates navigation and flow within the home feature

import SwiftUI

struct HomeCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(viewModel: viewModel)
                case 1:
                    PTView()
                case 2:
                    Color.gymtimeBackground  // Placeholder for Feed
                case 3:
                    Color.gymtimeBackground  // Placeholder for Profile
                default:
                    HomeView(viewModel: viewModel)
                }
            }
            
            // Custom Bottom Navigation
            BottomNavBarView(selectedTab: $selectedTab)
        }
    }
} 