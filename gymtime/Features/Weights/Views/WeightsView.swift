// 📄 Displays the user's benchmark weights for different exercises

import SwiftUI

struct WeightsView: View {
    @ObservedObject var viewModel: WeightsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Benchmark Weights")
                                .font(.title)
                                .padding(.top)
                            
                            // TODO: Add weights display UI
                            // This will be implemented when we work on the data structure
                            Text("Coming Soon")
                                .foregroundColor(.gymtimeTextSecondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 