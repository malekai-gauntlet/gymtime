// 📄 Coordinates navigation and flow within the weights feature

import SwiftUI

struct WeightsCoordinator: View {
    @StateObject private var viewModel = WeightsViewModel()
    
    var body: some View {
        WeightsView(viewModel: viewModel)
    }
} 