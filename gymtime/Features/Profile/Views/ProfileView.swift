/*
 * 🖼️ What is this file for?
 * -------------------------
 * This is the main profile view that shows the user's gym progress and achievements.
 * It displays workout statistics, milestones, and progress towards goals.
 */

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingAuth = false
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.gymtimeText)
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                        Text("Loading profile...")
                            .foregroundColor(.gymtimeTextSecondary)
                            .padding(.top)
                        Spacer()
                    }
                } else if let error = viewModel.error {
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
                                await viewModel.refreshProfile()
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
                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Image
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(viewModel.username?.prefix(1).uppercased() ?? "")
                                        .font(.title.bold())
                                        .foregroundColor(.gymtimeText)
                                )
                            
                            // Name and Username with Edit Button
                            VStack(spacing: 8) {
                                Button {
                                    showingEditProfile = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.gymtimeAccent)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(viewModel.displayName ?? "")
                                        .font(.title2.bold())
                                        .foregroundColor(.gymtimeText)
                                    
                                    Text("@\(viewModel.username ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                            }
                        }
                        .padding(.top)
                        
                        // Progress Section - Moved up above the Stats Grid
                        if !viewModel.progressData.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("RECENT PROGRESS")
                                    .font(.headline)
                                    .foregroundColor(.gymtimeTextSecondary)
                                    .padding(.horizontal)
                                
                                // Progress Chart
                                ChartView(data: viewModel.progressData)
                                    .frame(height: 200)
                                    .padding(.horizontal, 12)
                            }
                        }
                        
                        // Stats Grid - Now below the Progress Section
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
                            
                            // Weekly Goal
                            StatCard(
                                title: "WEEKLY GOAL",
                                value: "\(viewModel.workoutsThisWeek)/\(viewModel.weeklyGoal)",
                                subtitle: "This week"
                            )
                            
                            // Current Streak
                            StatCard(
                                title: "CURRENT STREAK",
                                value: "\(viewModel.currentStreak)",
                                subtitle: "days"
                            )
                            
                            // Personal Records
                            StatCard(
                                title: "PERSONAL RECORDS",
                                value: "\(viewModel.personalRecords)",
                                subtitle: "All time"
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 32)
                    }
                }
            }
            .background(Color.gymtimeBackground)
            .navigationBarTitle("Profile", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingLogoutConfirmation = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.gymtimeAccent)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
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
        }
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
    
    // Selected day
    @State private var selectedDayIndex: Int? = nil
    
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
    
    // Calculate the maximum volume for the scale
    private var maxVolume: Double {
        // Either use the actual max + some padding or use 15,000 as suggested
        return 15000 // Using a fixed max of 15k as requested
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
    
    // Format the stats for display
    private var selectedDayStats: (date: String, weight: String) {
        guard let point = selectedPoint else {
            return ("No data", "0 lbs")
        }
        
        let dateString = fullDateFormatter.string(from: point.date)
        let weightString = "\(Int(point.actualVolume)) lbs"
        
        return (dateString, weightString)
    }
    
    // Handle day selection based on x position
    private func daySelected(at xPosition: CGFloat, width: CGFloat) {
        guard !data.isEmpty else { return }
        
        let stepWidth = width / CGFloat(max(1, data.count - 1))
        let index = Int((xPosition / stepWidth).rounded())
        
        // Ensure index is within bounds
        if index >= 0 && index < data.count {
            selectedDayIndex = index
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Daily stats section
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDayStats.date)
                    .font(.headline)
                    .foregroundColor(.gymtimeText)
                    .padding(.top, 4)
                
                HStack(spacing: 6) {
                    Text("Total weight:")
                        .font(.subheadline)
                        .foregroundColor(.gymtimeTextSecondary)
                    
                    Text(selectedDayStats.weight)
                        .font(.subheadline.bold())
                        .foregroundColor(.gymtimeAccent)
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            
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
                    .frame(width: 60, alignment: .trailing)
                    .offset(x: geometry.size.width - 60, y: 0)
                    
                    // Horizontal grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<yAxisLabels.count, id: \.self) { _ in
                            Spacer()
                            Divider()
                                .background(Color.gymtimeTextSecondary.opacity(0.1))
                        }
                    }
                    .frame(width: geometry.size.width - 70)
                    
                    // Data area (filled)
                    if data.count > 1 {
                        Path { path in
                            // Calculate points for area
                            let points = data.enumerated().map { index, point -> CGPoint in
                                let x = (geometry.size.width - 70) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                                let y = geometry.size.height * (1 - CGFloat(point.actualVolume / maxVolume))
                                return CGPoint(x: x, y: y)
                            }
                            
                            // Start from bottom left
                            path.move(to: CGPoint(x: 0, y: geometry.size.height))
                            
                            // Add line to first point
                            if let firstPoint = points.first {
                                path.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
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
                            let x = (geometry.size.width - 70) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                            let y = geometry.size.height * (1 - CGFloat(point.actualVolume / maxVolume))
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
                    if let index = selectedDayIndex, index >= 0, index < data.count {
                        let x = (geometry.size.width - 70) * CGFloat(index) / CGFloat(max(1, data.count - 1))
                        
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
                        let x = (geometry.size.width - 70)
                        
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
                                    daySelected(at: min(value.location.x, geometry.size.width - 70), width: geometry.size.width - 70)
                                }
                        )
                }
            }
            
            // X-axis date labels
            HStack(spacing: 0) {
                // Group dates by showing only every other date to avoid crowding
                ForEach(Array(stride(from: 0, to: data.count, by: max(1, data.count > 7 ? 2 : 1))), id: \.self) { index in
                    if index < data.count {
                        Text(dateFormatter.string(from: data[index].date))
                            .font(.caption2)
                            .foregroundColor(.gymtimeTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 60) // Match the y-axis label width
        }
        .onAppear {
            // Find the most recent day with actual data
            if selectedDayIndex == nil {
                if let index = data.indices.last(where: { data[$0].actualVolume > 0 }) {
                    selectedDayIndex = index
                } else {
                    selectedDayIndex = data.indices.last
                }
            }
        }
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