import SwiftUI

/// FeedView displays a feed of workouts from the user's network
/// Similar to Fitbod's clean, dark interface
struct FeedView: View {
    // MARK: - Properties
    @State private var workouts: [WorkoutFeedEntry] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var proppedWorkouts: Set<UUID> = []
    @State private var showingActivityView = false
    @State private var unreadActivityCount = 0 // Default to 0, will be updated when fetching from backend
    @State private var lastActivityReadTime: Date? = UserDefaults.standard.object(forKey: "lastActivityReadTime") as? Date
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(workouts) { workout in
                        VStack(alignment: .leading, spacing: 0) {
                            // User Info Section
                            HStack(alignment: .center) {
                                // User Avatar
                                Circle()
                                    .fill(Color.gymtimeAccent.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(workout.userName.prefix(1))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gymtimeAccent)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.userName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(workout.location)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gymtimeTextSecondary)
                                }
                                
                                Spacer()
                                
                                Text(workout.timestamp.formatted(date: .numeric, time: .omitted))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                            .padding(.bottom, 12)
                            
                            // Workout Info Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(workout.workoutType)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(workout.achievement)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineSpacing(4)
                                    }
                                    
                                    Spacer()
                                    
                                    // Props Button (formerly Like Button)
                                    HStack(spacing: 4) {
                                        if workout.propsCount > 0 {
                                            Text("\(workout.propsCount)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gymtimeTextSecondary)
                                        }
                                        
                                        Button(action: {
                                            Task {
                                                do {
                                                    try await toggleProps(for: workout.id)
                                                } catch {
                                                    // Revert local state if database operation failed
                                                    if proppedWorkouts.contains(workout.id) {
                                                        proppedWorkouts.remove(workout.id)
                                                    } else {
                                                        proppedWorkouts.insert(workout.id)
                                                    }
                                                    
                                                    showingError = true
                                                    errorMessage = "Failed to update props: \(error.localizedDescription)"
                                                    print("❌ Error toggling props: \(error)")
                                                }
                                            }
                                        }) {
                                            Image(systemName: proppedWorkouts.contains(workout.id) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                .font(.system(size: 20))
                                                .foregroundColor(proppedWorkouts.contains(workout.id) ? .gymtimeAccent : .gymtimeTextSecondary)
                                        }
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
                        .padding(.horizontal, 16)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(white: 0.08))  // Slightly lighter background
            .navigationBarTitle("Feed", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingActivityView = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gymtimeAccent)
                                .padding(5)
                            
                            if unreadActivityCount > 0 {
                                Text("\(unreadActivityCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingActivityView, onDismiss: {
            // Update our state with the saved last read time
            lastActivityReadTime = UserDefaults.standard.object(forKey: "lastActivityReadTime") as? Date
        }) {
            ActivityView(unreadCount: $unreadActivityCount)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await checkViewStructure()
                await loadWorkouts()
                await fetchUnreadActivityCount()
            }
        }
    }
    
    // Verify the database view is working correctly
    private func checkViewStructure() async {
        do {
            print("🔎 DB Debug: Checking workout_props_with_users view structure")
            
            // Run a simple query to get all columns
            let result = try await supabase
                .from("workout_props_with_users")
                .select("*")
                .limit(1)
                .execute()
                .data
            
            // Handle data directly without conditional binding
            let jsonString = String(data: result, encoding: .utf8) ?? "No readable data"
            print("🔎 DB Debug: View structure: \(jsonString)")
        } catch {
            print("❌ DB Debug: Error checking view: \(error)")
        }
    }
    
    // MARK: - Methods
    private func loadWorkouts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch workouts from workout_profiles view which includes user information
            let response: [WorkoutProfileEntry] = try await supabase
                .from("workout_profiles")
                .select()
                .order("date", ascending: false)
                .limit(10)
                .execute()
                .value
            
            // Create base workout feed entries
            var feedEntries = response.map { workout in
                WorkoutFeedEntry(
                    id: workout.id,
                    userName: workout.username.isEmpty ? (workout.fullName ?? "User") : workout.username,
                    workoutType: workout.exercise,
                    location: "Gym", // Default location for now
                    achievement: formatAchievement(workout),
                    timestamp: workout.date
                )
            }
            
            // Get prop counts for these workouts
            if !feedEntries.isEmpty {
                // Get all workout IDs as a comma-separated string for the query
                let workoutIdList = feedEntries.map { $0.id.uuidString }
                print("🔍 Looking for props for \(workoutIdList.count) workouts")
                
                // Get all props entries for these workouts
                struct WorkoutPropEntry: Decodable {
                    let workout_id: String
                    let user_id: String
                }
                
                let allProps: [WorkoutPropEntry] = try await supabase
                    .from("workout_props")
                    .select("workout_id, user_id")
                    .execute()
                    .value
                
                print("🔍 Found \(allProps.count) total props entries")
                
                // SIMPLER APPROACH: Create counts directly from all props
                var propCountsByWorkout: [String: Int] = [:]
                
                for prop in allProps {
                    // Check if this is one of our workouts
                    if workoutIdList.contains(where: { $0.lowercased() == prop.workout_id.lowercased() }) {
                        propCountsByWorkout[prop.workout_id, default: 0] += 1
                    }
                }
                
                print("🔍 Counted props for \(propCountsByWorkout.count) workouts")
                
                // Update workout entries with prop counts
                for (index, entry) in feedEntries.enumerated() {
                    // Try both regular and lowercase comparison
                    if let count = propCountsByWorkout[entry.id.uuidString] {
                        feedEntries[index].propsCount = count
                        print("🔍 Workout \(entry.workoutType): \(count) props")
                    } else if let count = propCountsByWorkout[entry.id.uuidString.lowercased()] {
                        feedEntries[index].propsCount = count
                        print("🔍 Workout \(entry.workoutType) (lowercase match): \(count) props")
                    }
                }
            }
            
            // Update state
            workouts = feedEntries
        } catch {
            showingError = true
            errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }
    }
    
    /// Toggles props for a workout and saves to Supabase
    private func toggleProps(for workoutId: UUID) async throws {
        // Update local state immediately for responsive UI
        let isRemoving = proppedWorkouts.contains(workoutId)
        
        if isRemoving {
            proppedWorkouts.remove(workoutId)
            
            // Update props count in the UI immediately
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index].propsCount = max(0, workouts[index].propsCount - 1)
            }
        } else {
            proppedWorkouts.insert(workoutId)
            
            // Update props count in the UI immediately
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index].propsCount += 1
            }
        }
        
        // Check if user is logged in - session is async and user.id is now non-optional
        let session = await supabase.auth.session
        let userId = session.user.id
        
        if isRemoving {
            // Remove prop from database
            _ = try await supabase
                .from("workout_props")
                .delete()
                .eq("workout_id", value: workoutId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            print("📱 Removed props for workout: \(workoutId)")
        } else {
            // Add prop to database
            _ = try await supabase
                .from("workout_props")
                .insert(
                    WorkoutProp(
                        workoutId: workoutId,
                        userId: userId
                    )
                )
                .execute()
            
            print("📱 Added props for workout: \(workoutId)")
        }
    }
    
    // Helper function to format the achievement string
    private func formatAchievement(_ workout: WorkoutProfileEntry) -> String {
        var parts: [String] = []
        
        if let weight = workout.weight {
            parts.append("\(Int(weight))lbs")
        }
        
        if let sets = workout.sets, let reps = workout.reps {
            parts.append("\(sets)×\(reps)")
        }
        
        return parts.isEmpty ? "Completed workout" : parts.joined(separator: " • ")
    }
    
    private func fetchUnreadActivityCount() async {
        do {
            // Get current user's ID
            let session = await supabase.auth.session
            let userId = session.user.id
            print("🔎 UnreadCount Debug: User ID = \(userId.uuidString)")
            
            // Create base query to count props
            var query = supabase
                .from("workout_props_with_users")
                .select("*", count: .exact)
                .eq("workout_user_id", value: userId.uuidString.lowercased())
            
            // If we have a last read time, only count newer activities
            if let lastRead = lastActivityReadTime {
                // Format date to ISO8601 for Supabase query
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                let dateString = formatter.string(from: lastRead)
                
                // Add filter for newer activities
                query = query.gt("created_at", value: dateString)
                print("🔎 UnreadCount Debug: Only counting props after \(dateString)")
            } else {
                print("🔎 UnreadCount Debug: No last read time, counting all props")
            }
            
            // Execute the query
            let countResult = try await query.execute()
            
            // Safely unwrap the optional count
            let count = countResult.count ?? 0
            print("🔎 UnreadCount Debug: Found \(count) unread props")
            
            // For MVP, we're considering all matching the filter as unread
            unreadActivityCount = count
            
        } catch {
            print("❌ Error fetching unread count: \(error)")
            print("❌ UnreadCount Debug: Detailed error: \(String(describing: error))")
        }
    }
}

// MARK: - Preview
#Preview {
    FeedView()
}

// MARK: - Supporting Types
/// Model representing a single workout entry in the feed
struct WorkoutFeedEntry: Identifiable {
    let id: UUID
    let userName: String
    let workoutType: String
    let location: String
    let achievement: String
    let timestamp: Date
    var propsCount: Int = 0 // Count of props for this workout
}

/// Model for sending workout props to Supabase
struct WorkoutProp: Codable {
    let workout_id: String
    let user_id: String
    
    init(workoutId: UUID, userId: UUID) {
        self.workout_id = workoutId.uuidString
        self.user_id = userId.uuidString
    }
}

// MARK: - Activity View
struct ActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var unreadCount: Int  // Add binding to update parent's unread count
    @State private var activities: [ActivityItem] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading && activities.isEmpty {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading activity...")
                            .foregroundColor(.gymtimeTextSecondary)
                    }
                } else {
                    List {
                        if activities.isEmpty {
                            Text("No activities yet")
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding()
                        } else {
                            ForEach(activities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitle("Activity", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                // Mark all as read when dismissing
                markAllAsRead()
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color(white: 0.08))
        }
        .onAppear {
            Task {
                await loadActivity()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func markAllAsRead() {
        // Reset the counter
        unreadCount = 0
        
        // Save the current time as the last time activities were read
        let now = Date()
        UserDefaults.standard.set(now, forKey: "lastActivityReadTime")
        
        // We need to update the parent's state variable too, since it's initialized from UserDefaults
        // This will be done when the sheet is dismissed through the binding
    }
    
    private func loadActivity() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current user's ID
            let session = await supabase.auth.session
            let userId = session.user.id
            print("🔎 Activity Debug: User ID = \(userId.uuidString)")
            
            // Define data structures for our queries
            struct PropActivity: Decodable {
                let workout_id: String
                let user_id: String
                let username: String?
                let full_name: String?
                let exercise: String
                let created_at: String
            }
            
            print("🔎 Activity Debug: Starting to fetch props with query:")
            print("🔎 Activity Debug: SELECT workout_id, user_id, username, full_name, exercise, created_at")
            print("🔎 Activity Debug: FROM workout_props_with_users")
            print("🔎 Activity Debug: WHERE workout_user_id = '\(userId.uuidString)'")
            
            // Fetch props given to my workouts
            let receivedProps: [PropActivity] = try await supabase
                .from("workout_props_with_users")
                .select("workout_id, user_id, username, full_name, exercise, created_at")
                .eq("workout_user_id", value: userId.uuidString.lowercased())
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            print("🔎 Activity Debug: Received \(receivedProps.count) props")
            
            // Log the first few props for debugging
            if !receivedProps.isEmpty {
                print("🔎 Activity Debug: First prop details:")
                let firstProp = receivedProps[0]
                print("🔎 Activity Debug: - workout_id: \(firstProp.workout_id)")
                print("🔎 Activity Debug: - user_id: \(firstProp.user_id)")
                print("🔎 Activity Debug: - username: \(String(describing: firstProp.username))")
                print("🔎 Activity Debug: - exercise: \(firstProp.exercise)")
                print("🔎 Activity Debug: - created_at: \(firstProp.created_at)")
            } else {
                print("🔎 Activity Debug: No props received from query")
                
                // Let's run a simplified query to check if the view has data
                let testQuery: [PropActivity] = try await supabase
                    .from("workout_props_with_users")
                    .select("workout_id, user_id, username, full_name, exercise, created_at")
                    .limit(5)
                    .execute()
                    .value
                
                print("🔎 Activity Debug: Test query without filters returned \(testQuery.count) results")
                
                // Check if our SQL view is properly formed
                print("🔎 Activity Debug: Checking view structure:")
                let countResult = try await supabase
                    .from("workout_props_with_users")
                    .select("*", count: .exact)
                    .execute()
                
                print("🔎 Activity Debug: Total rows in view: \(countResult.count ?? 0)")
            }
            
            // Convert to activity items
            var allActivities: [ActivityItem] = []
            
            // Group props by workout for more condensed view
            var workoutProps: [String: [PropActivity]] = [:]
            
            for prop in receivedProps {
                let workoutId = prop.workout_id
                if workoutProps[workoutId] == nil {
                    workoutProps[workoutId] = []
                }
                workoutProps[workoutId]?.append(prop)
            }
            
            print("🔎 Activity Debug: Grouped props into \(workoutProps.count) workouts")
            
            // Create activity items from grouped props
            for (workoutId, props) in workoutProps {
                print("🔎 Activity Debug: Processing workout ID \(workoutId) with \(props.count) props")
                
                if let firstProp = props.first {
                    print("🔎 Activity Debug: First prop created_at: \(firstProp.created_at)")
                    
                    // Create a properly configured date formatter
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    if let date = dateFormatter.date(from: firstProp.created_at) {
                        let exercise = firstProp.exercise
                        
                        // Format the content based on number of props
                        var content = ""
                        if props.count == 1 {
                            // Single prop
                            let propUser = firstProp.username?.isEmpty ?? true ? (firstProp.full_name ?? "User") : firstProp.username ?? "User"
                            content = "\(propUser) gave you props on \(exercise)"
                        } else {
                            // Multiple props for same workout
                            let propUser = firstProp.username?.isEmpty ?? true ? (firstProp.full_name ?? "User") : firstProp.username ?? "User"
                            content = "\(propUser) and \(props.count - 1) others gave you props on \(exercise)"
                        }
                        
                        print("🔎 Activity Debug: Created content: \(content)")
                        
                        // Create activity item
                        let item = ActivityItem(
                            id: UUID(),
                            type: .receivedProps,
                            userName: firstProp.username?.isEmpty ?? true ? (firstProp.full_name ?? "User") : firstProp.username ?? "User",
                            userAvatar: String(firstProp.username?.prefix(1).uppercased() ?? "U"),
                            content: content,
                            timestamp: date,
                            isRead: false,
                            relatedId: workoutId
                        )
                        
                        allActivities.append(item)
                        print("🔎 Activity Debug: Added activity item for \(exercise)")
                    } else {
                        print("❌ Activity Debug: Failed to parse date from \(firstProp.created_at)")
                    }
                }
            }
            
            // Update state
            self.activities = allActivities
            print("🔎 Activity Debug: Final activities count: \(allActivities.count)")
            
            // Update unread count
            if allActivities.count > 0 {
                unreadCount = allActivities.count
                print("🔎 Activity Debug: Updated unread count to \(unreadCount)")
            }
            
        } catch {
            showingError = true
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            print("❌ Error loading activities: \(error)")
            
            // Log the full error details
            print("❌ Activity Debug: Detailed error: \(String(describing: error))")
        }
    }
}

// Activity row component for the notification list
struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            Circle()
                .fill(activity.isRead ? Color.gymtimeAccent.opacity(0.1) : Color.gymtimeAccent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(activity.userAvatar)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gymtimeAccent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Content
                Text(activity.content)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Timestamp
                Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundColor(.gymtimeTextSecondary)
            }
            
            Spacer()
            
            // Activity Icon
            activityIcon
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(white: 0.12))
    }
    
    // Icon matching the activity type
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .receivedProps:
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(.gymtimeAccent)
            case .propSuggestion:
                Image(systemName: "hand.thumbsup")
                    .foregroundColor(.gymtimeTextSecondary)
            case .receivedComment:
                Image(systemName: "bubble.right.fill")
                    .foregroundColor(.gymtimeAccent)
            case .receivedReaction:
                Image(systemName: "face.smiling.fill")
                    .foregroundColor(.gymtimeAccent)
            }
        }
        .font(.system(size: 14))
    }
}

// Model for Activity items
struct ActivityItem: Identifiable {
    let id: UUID
    let type: ActivityType
    let userName: String
    let userAvatar: String
    let content: String
    let timestamp: Date
    var isRead: Bool = false
    var relatedId: String? = nil  // Related workout ID or other reference
}

// Types of activities
enum ActivityType {
    case receivedProps       // When someone gives you props on your workout
    case propSuggestion      // When the app suggests giving props to someone
    case receivedComment     // When someone comments on your workout
    case receivedReaction    // When someone reacts to your comment/workout
} 