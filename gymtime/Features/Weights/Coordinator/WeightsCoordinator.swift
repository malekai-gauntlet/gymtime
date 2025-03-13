// 📄 Coordinates navigation and flow within the weights feature

import SwiftUI
import Supabase

struct WeightsCoordinator: View {
    @StateObject private var viewModel: WeightsViewModel
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: WeightsViewModel(supabase: supabase))
    }
    
    var body: some View {
        WeightsView(viewModel: viewModel)
    }
} 