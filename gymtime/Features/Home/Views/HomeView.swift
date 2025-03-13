// 📄 Main home screen view displaying workout summary and quick actions

import SwiftUI

// Horizontal swipe handler
struct HorizontalSwipeHandler: ViewModifier {
    let onSwipe: (Bool) -> Void // true for right, false for left
    let isEditing: Bool
    let isSuggestionsVisible: Bool
    
    // Minimum distance to trigger a horizontal swipe
    private let horizontalThreshold: CGFloat = 50
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture()
                    .onEnded { gesture in
                        // Only process horizontal swipes if not editing and suggestions aren't visible
                        if !isEditing && !isSuggestionsVisible {
                            let horizontalMovement = abs(gesture.translation.width)
                            let verticalMovement = abs(gesture.translation.height)
                            
                            // Only trigger if primarily horizontal (with bias toward vertical)
                            if horizontalMovement > verticalMovement * 1.2 && 
                               horizontalMovement > horizontalThreshold {
                                print("👉 Horizontal swipe detected: \(gesture.translation.width > 0 ? "RIGHT" : "LEFT")")
                                onSwipe(gesture.translation.width > 0)
                            }
                        }
                    }
            )
    }
}

extension View {
    func horizontalSwipe(onSwipe: @escaping (Bool) -> Void, isEditing: Bool, isSuggestionsVisible: Bool) -> some View {
        self.modifier(HorizontalSwipeHandler(onSwipe: onSwipe, isEditing: isEditing, isSuggestionsVisible: isSuggestionsVisible))
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedTab: Int = 0
    @State private var showingVoiceLogger = false
    @State private var isEditing = false
    
    // Tooltip state tracking
    @State private var hasSeenOnboarding = false
    @State private var isLoadingOnboardingState = true
    
    // Active tooltip tracking
    @State private var showingRecordTooltip = false
    @State private var showingExampleTooltip = false
    @State private var showingPlusTooltip = false
    
    // Button position tracking
    @State private var recordButtonFrame: CGRect = .zero
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Section
                CalendarView(viewModel: viewModel)
                
                // Workout Tracking Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Workouts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gymtimeText)
                        
                        Spacer()
                        
                        Menu {
                            if viewModel.isLoadingTemplates {
                                Text("Loading templates...")
                            } else if viewModel.recentTemplates.isEmpty {
                                Text("Workout splits of the past four sessions will show here.")
                            } else {
                                ForEach(viewModel.recentTemplates) { template in
                                    Button(action: {
                                        Task {
                                            await viewModel.applyTemplate(template)
                                        }
                                    }) {
                                        Text(template.displayText)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if !viewModel.aiWorkoutSummary.isEmpty {
                                    Text(viewModel.aiWorkoutSummary
                                        .trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
                                        + " Day"
                                    )
                                        .font(.subheadline)
                                        .foregroundColor(.gymtimeTextSecondary)
                                        .animation(.easeInOut, value: viewModel.aiWorkoutSummary)
                                } else if !viewModel.isLoadingSummary {
                                    Text("")
                                        .font(.subheadline)
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                                
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gymtimeAccent)
                            }
                        }
                        
                        if viewModel.isLoadingSummary {
                            HStack(spacing: 4) {
                                Text("Summarizing")
                                    .font(.subheadline)
                                    .foregroundColor(.gymtimeTextSecondary)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, -12)
                .padding(.bottom, 12)
                .background(Color.gymtimeBackground)
                
                // Workout Table with horizontal swipe handling
                WorkoutTableView(
                    workouts: $viewModel.workouts,
                    viewModel: viewModel,
                    isEditing: $isEditing,
                    showingAnonymousConversion: $viewModel.showAnonymousConversion
                )
                    .horizontalSwipe(
                        onSwipe: { isRight in
                            if isRight {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.calendarState.selectedDate) ?? Date())
                            } else {
                                viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.calendarState.selectedDate) ?? Date())
                            }
                        },
                        isEditing: isEditing,
                        isSuggestionsVisible: viewModel.isSuggestionsVisible
                    )
            }
            .background(Color.gymtimeBackground)
            .tooltip(
                isVisible: showingRecordTooltip,
                title: "Record Your Workout",
                message: "Log your workout with voice",
                arrowOffset: CGPoint(x: 0, y: 220),
                onDismiss: {
                    showingRecordTooltip = false
                    if !hasSeenOnboarding {
                        // Show the example tooltip after record tooltip
                        showingExampleTooltip = true
                    }
                }
            )
            .tooltip(
                isVisible: showingExampleTooltip,
                title: "You can say:",
                message: "\"Shoulder Press, 35lbs, 3 sets 8 reps, felt great\"",
                arrowOffset: CGPoint(x: 0, y: 220),
                onDismiss: {
                    showingExampleTooltip = false
                    if !hasSeenOnboarding {
                        Task {
                            do {
                                let userId = try await supabase.auth.session.user.id
                                try await supabase
                                    .from("profiles")
                                    .update(["has_seen_onboarding": true])
                                    .eq("id", value: userId)
                                    .execute()
                                
                                hasSeenOnboarding = true
                                // Show the plus tooltip after example tooltip
                                showingPlusTooltip = true
                            } catch {
                                print("❌ Error updating onboarding state: \(error)")
                            }
                        }
                    }
                }
            )
            .tooltip(
                isVisible: showingPlusTooltip,
                title: "Add Exercises",
                message: "Add exercises manually",
                arrowOffset: CGPoint(x: 77, y: 163),
                onDismiss: {
                    showingPlusTooltip = false
                }
            )
            .sheet(isPresented: $showingVoiceLogger) {
                Text("Voice Logger Coming Soon")
            }
            .onAppear {
                print("🔍 HomeView appeared")
                
                // Load templates
                Task {
                    await viewModel.loadRecentTemplates()
                }
                
                // Load onboarding state from Supabase
                Task {
                    do {
                        let userId = try await supabase.auth.session.user.id
                        let profile: Profile = try await supabase
                            .from("profiles")
                            .select()
                            .eq("id", value: userId)
                            .single()
                            .execute()
                            .value
                        
                        hasSeenOnboarding = profile.hasSeenOnboarding
                        isLoadingOnboardingState = false
                        
                        // Only show tooltip if user hasn't seen onboarding
                        if !hasSeenOnboarding {
                            print("🔍 First time user - showing record tooltip")
                            showingRecordTooltip = true
                        }
                    } catch {
                        print("❌ Error loading onboarding state: \(error)")
                        isLoadingOnboardingState = false
                    }
                }
            }
            .onChange(of: showingRecordTooltip) { newValue in
                print("🔍 showingRecordTooltip changed to: \(newValue)")
            }
        }
    }
}

#Preview {
    HomeCoordinator()
}