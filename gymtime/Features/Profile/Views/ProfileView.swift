/*
 * 🖼️ What is this file for?
 * -------------------------
 * This is the main profile view that shows the user's gym progress and achievements.
 * It displays workout statistics, milestones, and progress towards goals.
 */

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var progressionViewModel = ProgressionViewModel()
    @State private var showingEditProfile = false
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingAuth = false
    @State private var showingLogoutConfirmation = false
    @State private var isRefreshing = false
    
    // Tooltip state
    @State private var hasSeenTooltip = false
    @State private var isLoadingTooltipState = true
    @State private var showingTooltip = false
    
    // Recent Progress tooltip state
    @State private var showingProgressTooltip = false
    
    // Add state for anonymous conversion
    @State private var showingAnonymousConversion = false
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let error = viewModel.error {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .padding(.top, 100)
                        Text(error)
                            .foregroundColor(.gymtimeTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            Task {
                                await refreshData()
                            }
                        }
                        .padding()
                        .background(Color.gymtimeAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 24) {
                        // Profile Header - Horizontal layout with proper centering
                        HStack(spacing: 20) {
                            // Profile Image
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(viewModel.username?.prefix(1).uppercased() ?? "")
                                        .font(.title.bold())
                                        .foregroundColor(.gymtimeText)
                                )
                            
                            // Name, Username, and Edit Button
                            VStack(alignment: .leading, spacing: 8) {
                                // Name and Username
                                Text(viewModel.displayName ?? "")
                                    .font(.title2.bold())
                                    .foregroundColor(.gymtimeText)
                                
                                Text("@\(viewModel.username ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.gymtimeTextSecondary)
                                
                                // Edit Button
                                Button {
                                    if viewModel.isAnonymous {
                                        showingAnonymousConversion = true
                                    } else {
                                        showingEditProfile = true
                                    }
                                } label: {
                                    Image(systemName: viewModel.isAnonymous ? "person.crop.circle.badge.plus" : "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.gymtimeAccent)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)  // Added vertical padding to the entire VStack
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Stats Grid - Reduced to 2-card layout
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Workouts
                            StatCard(
                                title: "WORKOUTS",
                                value: "\(viewModel.totalWorkouts)",
                                subtitle: "All time"
                            )
                            
                            // Current Streak
                            StatCard(
                                title: "CURRENT STREAK",
                                value: "\(viewModel.currentStreak)",
                                subtitle: "days"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Strength Progression Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("STRENGTH PROGRESSION")
                                    .font(.headline)
                                    .foregroundColor(.gymtimeTextSecondary)
                                
                                Spacer()
                                
                                NavigationLink(destination: ProgressionView()) {
                                    Text("View All")
                                        .font(.caption.bold())
                                        .foregroundColor(.gymtimeAccent)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Use the ProgressionCard here
                            ProgressionCard(viewModel: progressionViewModel)
                                .padding(.horizontal)
                        }
                        
                        // Recent Progress Section
                        if !viewModel.progressData.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("RECENT PROGRESS")
                                        .font(.headline)
                                        .foregroundColor(.gymtimeTextSecondary)
                                    
                                    Button {
                                        showingProgressTooltip = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.gymtimeAccent)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Progress Chart - Keep the current implementation
                                if let dateRange = getLastWeekDateRange(data: viewModel.progressData) {
                                    ChartView(
                                        data: getLastWeekData(data: viewModel.progressData),
                                        dateRange: dateRange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer(minLength: 32)
                    }
                }
            }
            .background(Color.gymtimeBackground)
            .navigationBarTitle("Profile", displayMode: .inline)
            .simpleTooltip(
                isVisible: showingProgressTooltip,
                title: "Weight Calculation",
                message: "The chart shows your total weight lifted (weight × sets × reps) for each day.",
                onDismiss: {
                    showingProgressTooltip = false
                }
            )
            .tooltip(
                isVisible: showingTooltip,
                title: "Your Progress",
                message: "Track your progress in the charts below.",
                arrowOffset: CGPoint(x: 0, y: -100), // Position 100px above center
                onDismiss: {
                    showingTooltip = false
                    if !hasSeenTooltip {
                        Task {
                            do {
                                let userId = try await supabase.auth.session.user.id
                                try await supabase
                                    .from("profiles")
                                    .update(["has_seen_profile_tooltip": true])
                                    .eq("id", value: userId)
                                    .execute()
                                
                                hasSeenTooltip = true
                            } catch {
                                print("❌ Error updating profile tooltip state: \(error)")
                            }
                        }
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gymtimeAccent)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingLogoutConfirmation = true
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        
                        Button {
                            Task {
                                await exportWorkouts()
                            }
                        } label: {
                            Label("Export Workouts", systemImage: "square.and.arrow.up")
                        }
                        
                        Menu("More") {
                            Button(role: .destructive) {
                                handleDeleteAccount()
                            } label: {
                                Label("Delete Account", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gymtimeAccent)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnonymousConversion) {
                AnonymousConversionView(isPresented: $showingAnonymousConversion)
            }
            .fullScreenCover(isPresented: $showingAuth) {
                AuthenticationView(viewModel: AuthenticationViewModel(coordinator: coordinator))
            }
            .confirmationDialog("Are you sure you want to log out?", 
                              isPresented: $showingLogoutConfirmation,
                              titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await AuthenticationViewModel(coordinator: coordinator).signOut()
                        showingAuth = true
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Are you sure you want to delete your account?",
                              isPresented: $showingDeleteConfirmation,
                              titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteAccount()
                            // After successful deletion, sign out and show auth screen
                            await AuthenticationViewModel(coordinator: coordinator).signOut()
                            showingAuth = true
                        } catch {
                            // Error handling is already done in the ViewModel
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onAppear {
            Task {
                // Load tooltip state
                do {
                    let userId = try await supabase.auth.session.user.id
                    let profile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value
                    
                    hasSeenTooltip = profile.hasSeenProfileTooltip
                    isLoadingTooltipState = false
                    
                    if !hasSeenTooltip {
                        print("🔍 First time viewing profile tab - showing tooltip")
                        showingTooltip = true
                    }
                } catch {
                    print("❌ Error loading profile tooltip state: \(error)")
                    isLoadingTooltipState = false
                }
                
                await viewModel.refreshProfile()
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        // Refresh both view models
        await viewModel.refreshProfile()
        await progressionViewModel.fetchWorkoutProgression()
        
        isRefreshing = false
    }
    
    private func exportWorkouts() async {
        do {
            let csvString = try await viewModel.exportWorkoutsToCSV()
            
            // Get the Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fileName = "workouts_\(dateFormatter.string(from: Date())).csv"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // Write the CSV string to the file
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootViewController.view
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            // Show error alert using the ViewModel's error handler
            viewModel.handleExportError(error)
        }
    }
    
    private func handleDeleteAccount() {
        showingDeleteConfirmation = true
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.gymtimeText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gymtimeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct ChartView: View {
    // Chart data
    var data: [ProgressPoint]
    var dateRange: String
    
    // Selected day
    @State private var selectedDayIndex: Int? = nil
    @State private var isDateRangeVisible: Bool = true
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // Calculate the maximum volume for the scale based on actual data
    private var maxVolume: Double {
        // Find maximum volume in the data
        let dataMax = data.map { $0.actualVolume }.max() ?? 0
        
        // Add 20% padding to the maximum
        let maxWithPadding = dataMax * 1.2
        
        // Return either the calculated max or a default value if too small
        return max(maxWithPadding, 5000)
    }
    
    // Y-axis labels (weight values)
    private var yAxisLabels: [String] {
        // Create even increments from 0 to maxVolume
        let intervals = 3 // Reduced number of intervals for cleaner display
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return stride(from: 0, through: Int(maxVolume), by: Int(maxVolume) / intervals).map { 
            formatter.string(from: NSNumber(value: $0)) ?? "\($0)"
        }
    }
    
    // Get the total weight lifted for the entire week
    private var weeklyTotalWeight: Int {
        return Int(data.reduce(0) { $0 + $1.actualVolume })
    }
    
    // Get the selected point and compute stats
    private var selectedPoint: ProgressPoint? {
        guard let index = selectedDayIndex, index >= 0, index < data.count else {
            // If no selection, use the most recent data point with actual volume
            if let index = data.indices.last(where: { data[$0].actualVolume > 0 }) {
                return data[index]
            }
            return data.last
        }
        return data[index]
    }
    
    // Format the stats for display - now handles both week and day views
    private var displayStats: (date: String, weight: String) {
        if isDateRangeVisible {
            // Weekly stats
            return (dateRange, "\(weeklyTotalWeight) lbs")
        } else {
            // Daily stats
            guard let point = selectedPoint else {
                return ("No data", "0 lbs")
            }
            
            let dateString = fullDateFormatter.string(from: point.date)
            let weightString = "\(Int(point.actualVolume)) lbs"
            
            return (dateString, weightString)
        }
    }
    
    // Handle day selection based on x position
    private func daySelected(at xPosition: CGFloat, width: CGFloat) {
        guard !data.isEmpty else { return }
        
        let stepWidth = width / CGFloat(max(1, data.count - 1))
        let index = Int((xPosition / stepWidth).rounded())
        
        // Ensure index is within bounds
        if index >= 0 && index < data.count {
            selectedDayIndex = index
            isDateRangeVisible = false // Switch to showing selected day instead of date range
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date information section - consistent styling between week and day views
            VStack(alignment: .leading, spacing: 4) {
                Text(displayStats.date)
                    .font(.headline)
                    .foregroundColor(.gymtimeText)
                    .padding(.top, 4)
                
                HStack(spacing: 6) {
                    Text("Total weight lifted:")
                        .font(.subheadline)
                        .foregroundColor(.gymtimeTextSecondary)
                    
                    Text(displayStats.weight)
                        .font(.subheadline.bold())
                        .foregroundColor(.gymtimeAccent)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .onTapGesture {
                // Toggle between date range and selected day when tapped
                isDateRangeVisible.toggle()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Y-axis labels (right side)
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(yAxisLabels.reversed(), id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.gymtimeTextSecondary)
                                .frame(height: geometry.size.height / CGFloat(yAxisLabels.count - 1))
                        }
                    }
                    .frame(width: 40, alignment: .trailing)
                    .offset(x: geometry.size.width - 40, y: 0)
                    
                    // Horizontal grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<yAxisLabels.count, id: \.self) { _ in
                            Spacer()
                            Divider()
                                .background(Color.gymtimeTextSecondary.opacity(0.1))
                        }
                    }
                    .frame(width: geometry.size.width - 50)
                    
                    // Data area (filled)
                    if data.count > 1 {
                        Path { path in
                            // Calculate points for area
                            let points = data.enumerated().map { index, point -> CGPoint in
                                let x = (geometry.size.width - 50) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                                let y = point.actualVolume > 0 ? geometry.size.height * (1 - CGFloat(point.actualVolume / maxVolume)) : geometry.size.height
                                return CGPoint(x: x, y: y)
                            }
                            
                            // Start from bottom left
                            path.move(to: CGPoint(x: 0, y: geometry.size.height))
                            
                            // Add line to first point
                            if let firstPoint = points.first {
                                path.addLine(to: firstPoint)
                            }
                            
                            // Connect all points
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                            
                            // Complete the shape to bottom right
                            if let lastPoint = points.last {
                                path.addLine(to: CGPoint(x: lastPoint.x, y: geometry.size.height))
                            }
                            
                            // Close the path
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [Color.gymtimeAccent.opacity(0.7), Color.gymtimeAccent.opacity(0.1)]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    // Data line
                    Path { path in
                        // Calculate points
                        let points = data.enumerated().map { index, point -> CGPoint in
                            let x = (geometry.size.width - 50) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                            let y = point.actualVolume > 0 ? geometry.size.height * (1 - CGFloat(point.actualVolume / maxVolume)) : geometry.size.height
                            return CGPoint(x: x, y: y)
                        }
                        
                        // Draw path
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(Color.gymtimeAccent, lineWidth: 2)
                    
                    // Selected day indicator
                    if let index = selectedDayIndex, index >= 0, index < data.count, !isDateRangeVisible {
                        let x = (geometry.size.width - 50) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                        
                        // Vertical line at selected point
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        .stroke(
                            Color.white,
                            style: StrokeStyle(
                                lineWidth: 1,
                                dash: [4]
                            )
                        )
                        
                        // Selected point
                        let y = geometry.size.height * (1 - CGFloat(data[index].actualVolume / maxVolume))
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.gymtimeAccent, lineWidth: 2)
                            )
                            .position(x: x, y: y)
                    }
                    
                    // "Today" vertical line (if the last date is today)
                    if let lastDate = data.last?.date, Calendar.current.isDateInToday(lastDate) {
                        let x = (geometry.size.width - 50)
                        
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        .stroke(
                            Color.white.opacity(0.5),
                            style: StrokeStyle(
                                lineWidth: 1,
                                dash: [4]
                            )
                        )
                    }
                    
                    // Invisible overlay for tap detection
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    daySelected(at: min(value.location.x, geometry.size.width - 50), width: geometry.size.width - 50)
                                }
                        )
                }
            }
            
            // X-axis date labels - Keep the structure but hide the text
            HStack(spacing: 0) {
                // We'll keep the structure but not display any text
                ForEach(Array(stride(from: 0, to: data.count, by: 1)), id: \.self) { _ in
                    Text("")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 40) // Match the y-axis label width
        }
        .onAppear {
            // Find the most recent day with actual data for when detail is shown
            if selectedDayIndex == nil {
                if let index = data.indices.last(where: { data[$0].actualVolume > 0 }) {
                    selectedDayIndex = index
                } else {
                    selectedDayIndex = data.indices.last
                }
                // Start with date range visible
                isDateRangeVisible = true
            }
        }
    }
}

// MARK: - Helper Functions
extension ProfileView {
    // Filter data to show only the last 7 days
    private func getLastWeekData(data: [ProgressPoint]) -> [ProgressPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
        
        return data.filter { 
            let dayDate = calendar.startOfDay(for: $0.date)
            return dayDate >= startDate && dayDate <= endDate
        }
    }
    
    // Create a string representation of the date range (e.g., "Feb 20 - Feb 26, 2025")
    private func getLastWeekDateRange(data: [ProgressPoint]) -> String? {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        
        let startDateStr = dateFormatter.string(from: startDate)
        let endDateStr = dateFormatter.string(from: endDate)
        let yearStr = yearFormatter.string(from: endDate)
        
        return "\(startDateStr) - \(endDateStr), \(yearStr)"
    }
}

// Extension to safely access array indices
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}