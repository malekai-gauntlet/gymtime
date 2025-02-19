import SwiftUI

/// FeedEntryView displays a single workout entry in the feed
/// with user information, workout details, and social interactions
struct FeedEntryView: View {
    // MARK: - Properties
    let workout: WorkoutFeedEntry
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info Row
            HStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(workout.userName.prefix(1))
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))
                    )
                
                // User Info and Location
                VStack(alignment: .leading, spacing: 4) {
                    // User Name
                    Text(workout.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Location with icon
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(workout.location)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // More Options
                Menu {
                    Button("Share Workout", action: {})
                    Button("View Profile", action: {})
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            // Workout Details
            VStack(alignment: .leading, spacing: 8) {
                // Workout Type as Title
                Text(workout.workoutType)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                // Achievement
                if !workout.achievement.isEmpty {
                    Text(workout.achievement)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(.leading, 52) // Align with the text after profile picture
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        FeedEntryView(workout: WorkoutFeedEntry(
            id: UUID(),
            userName: "Robert Spies",
            workoutType: "Morning Run",
            location: "Deschutes National Forest, Oregon",
            achievement: "27.99 mi • 15,158 ft elevation",
            timestamp: Date()
        ))
        
        FeedEntryView(workout: WorkoutFeedEntry(
            id: UUID(),
            userName: "Sarah Chen",
            workoutType: "Strength Training",
            location: "LifeTime Sky NYC",
            achievement: "Bench Press: 225lbs × 5 • Deadlift: 315lbs × 3",
            timestamp: Date()
        ))
    }
    .background(Color(.systemBackground))
    .previewLayout(.sizeThatFits)
} 