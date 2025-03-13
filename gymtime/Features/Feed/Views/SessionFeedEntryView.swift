import SwiftUI
import Foundation

/// SessionFeedEntryView displays a grouped workout session in the feed
/// It shows multiple exercises done by the same user on the same day as a single entry
struct SessionFeedEntryView: View {
    // MARK: - Properties
    let session: WorkoutSessionEntry
    let onPropToggle: (String) -> Void
    
    @State private var isExpanded = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User Info Section
            HStack(alignment: .center) {
                // User Avatar
                Circle()
                    .fill(Color.gymtimeAccent.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(session.userName.prefix(1))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gymtimeAccent)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(session.location)
                        .font(.system(size: 14))
                        .foregroundColor(.gymtimeTextSecondary)
                }
                
                Spacer()
                
                Text(session.date.formatted(date: .numeric, time: .omitted))
                    .font(.system(size: 14))
                    .foregroundColor(.gymtimeTextSecondary)
            }
            .padding(.bottom, 12)
            
            // Session Summary Section
            VStack(alignment: .leading, spacing: 8) {
                // Session Summary (e.g., 5 exercises)
                HStack {
                    Text(session.summary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Props Button
                    HStack(spacing: 4) {
                        if session.propsCount > 0 {
                            Text("\(session.propsCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.gymtimeTextSecondary)
                        }
                        
                        Button(action: {
                            onPropToggle(session.id)
                        }) {
                            Image(systemName: session.isProppedByCurrentUser ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 20))
                                .foregroundColor(session.isProppedByCurrentUser ? .gymtimeAccent : .gymtimeTextSecondary)
                        }
                    }
                }
                
                // Primary Exercise Highlight (if available)
                if let summary = session.workoutSummary {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
                
                // Expandable Exercise List
                if session.exercises.count > 1 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(isExpanded ? "Hide details" : "Show all exercises")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gymtimeAccent)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gymtimeAccent)
                        }
                        .padding(.top, 8)
                    }
                    
                    if isExpanded {
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)
                        
                        ForEach(session.exercises.dropFirst()) { exercise in
                            ExerciseRow(exercise: exercise)
                                .padding(.vertical, 4)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Row Component
/// Displays a single exercise within the expanded session list
struct ExerciseRow: View {
    let exercise: ExerciseEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Exercise Icon
            Circle()
                .fill(Color.gymtimeAccent.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gymtimeAccent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(exercise.displayStats)
                    .font(.system(size: 14))
                    .foregroundColor(.gymtimeTextSecondary)
            }
            
            Spacer()
        }
    }
} 