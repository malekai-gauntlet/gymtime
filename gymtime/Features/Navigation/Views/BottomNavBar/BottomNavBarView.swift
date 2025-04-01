// 📄 Main bottom navigation bar with tab items for app-wide navigation

import SwiftUI

struct BottomNavBarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            NavBarItem(
                icon: "doc.text.fill",
                text: "Workouts",
                isSelected: selectedTab == 0
            )
            .onTapGesture { selectedTab = 0 }
            
            NavBarItem(
                icon: "number.circle.fill",
                text: "Weights",
                isSelected: selectedTab == 1
            )
            .onTapGesture { selectedTab = 1 }
            
            // PT View - Replaced with Progression View
            NavBarItem(
                icon: "chart.line.uptrend.xyaxis",
                text: "Progression",
                isSelected: selectedTab == 2
            )
            .onTapGesture { selectedTab = 2 }
            
            /* Props View - Commented out
            NavBarItem(
                icon: "hand.thumbsup.fill",
                text: "Props",
                isSelected: selectedTab == 3
            )
            .onTapGesture { selectedTab = 3 }
            */
            
            NavBarItem(
                icon: "person.fill",
                text: "Profile",
                isSelected: selectedTab == 4
            )
            .onTapGesture { selectedTab = 4 }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(
            Color.black.opacity(0.95)
                .edgesIgnoringSafeArea(.bottom)
        )
        .overlay(
            Divider()
                .background(Color.gymtimeTextSecondary.opacity(0.2))
                .frame(maxWidth: .infinity)
            , alignment: .top
        )
        .ignoresSafeArea(.keyboard)
    }
} 