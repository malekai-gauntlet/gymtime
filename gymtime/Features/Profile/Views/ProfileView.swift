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
    
    var body: some View {
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
                    
                    // Milestones Section
                    if !viewModel.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MILESTONES")
                                .font(.headline)
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.milestones) { milestone in
                                        MilestoneCard(milestone: milestone)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
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
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color.gymtimeBackground)
        .navigationBarTitle("Profile", displayMode: .inline)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(viewModel: viewModel)
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

struct MilestoneCard: View {
    let milestone: Milestone
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: milestone.iconName)
                .font(.system(size: 24))
                .foregroundColor(milestone.color)
            
            Text(milestone.title)
                .font(.caption)
                .foregroundColor(.gymtimeText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct ChartView: View {
    let data: [ProgressPoint]
    
    var body: some View {
        // Placeholder for actual chart implementation
        GeometryReader { geometry in
            Path { path in
                // Calculate points
                let points = data.enumerated().map { index, point -> CGPoint in
                    let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geometry.size.height * (1 - CGFloat(point.value) / 100)
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
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
