// 📄 Coordinates navigation and flow within the weights feature

import SwiftUI
import Supabase

struct WeightsCoordinator: View {
    @StateObject private var viewModel: WeightsViewModel
    let onWorkoutTapped: ((Date) -> Void)?
    
    init(supabase: SupabaseClient, onWorkoutTapped: ((Date) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: WeightsViewModel(supabase: supabase))
        self.onWorkoutTapped = onWorkoutTapped
    }
    
    var body: some View {
        WeightsView(viewModel: viewModel, onWorkoutTapped: onWorkoutTapped)
    }
} 