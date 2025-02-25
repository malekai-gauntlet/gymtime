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
                        
                        // Stats Grid
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
                        
                        // Progress Section
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
    let data: [ProgressPoint]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    // Find min and max actual volume values
    private var maxVolume: Double {
        return data.map { $0.actualVolume }.max() ?? 1000
    }
    
    private var yAxisLabels: [String] {
        let max = maxVolume
        let roundedMax = (max / 1000).rounded(.up) * 1000
        return ["0 lbs", "\(Int(roundedMax/2)) lbs", "\(Int(roundedMax)) lbs"]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Y-axis labels (right side)
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(yAxisLabels, id: \.self) { label in
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
                        ForEach(0..<yAxisLabels.count, id: \.self) { index in
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

