// 📄 Coordinates navigation and flow within the home feature

import SwiftUI
import Supabase
import Combine

struct HomeCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    @State private var selectedWorkoutDate: Date?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main content
                TabView(selection: $selectedTab) {
                    HomeView(viewModel: viewModel, selectedWorkoutDate: $selectedWorkoutDate)
                        .tag(0)
                        .zIndex(1) // Ensure HomeView is above other tabs
                    
                    TimerView()
                        .tag(1)
                    
                    /* Weights view - Commented out
                    WeightsCoordinator(supabase: supabase, onWorkoutTapped: { date in
                        selectedWorkoutDate = date
                        selectedTab = 0 // Switch to home tab
                    })
                        .tag(1)
                    */
                    
                    ProgressionView(onWorkoutTapped: { date in
                        selectedWorkoutDate = date
                        selectedTab = 0 // Switch to home tab
                    })
                        .tag(2)
                    
                    ProfileCoordinator()
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Bottom navigation bar
                VStack {
                    Spacer()
                    BottomNavBarView(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(.keyboard)
                .zIndex(2)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            print("🔍 HomeCoordinator appeared")
            setupKeyboardObservers()
        }
        .onChange(of: selectedTab) { newTab in
            print("🔍 Selected tab changed to: \(newTab)")
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    // Setup keyboard notification observers
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            withAnimation(.easeOut(duration: 0.16)) {
                isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            withAnimation(.easeOut(duration: 0.16)) {
                isKeyboardVisible = false
            }
        }
    }
    
    // Remove observers when view disappears
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
} 