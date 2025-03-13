import SwiftUI
import Foundation

/// FeedView displays a feed of workouts from the user's network
/// Similar to Fitbod's clean, dark interface
struct FeedView: View {
    // MARK: - Properties
    @State private var workouts: [WorkoutFeedEntry] = [] // Keep for backward compatibility during transition
    @State private var sessions: [WorkoutSessionEntry] = [] // New session-based model
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var proppedWorkouts: Set<UUID> = []
    @State private var proppedSessions: Set<String> = [] // Changed from Set<UUID> to Set<String>
    @State private var showingActivityView = false
    @State private var unreadActivityCount = 0 // Default to 0, will be updated when fetching from backend
    @State private var lastActivityReadTime: Date? = UserDefaults.standard.object(forKey: "lastActivityReadTime") as? Date
    @State private var useSessionView = true // Toggle between old and new UI during development
    @State private var sessionsOffset = 0 // Track how many sessions we've loaded
    
    // Tooltip state
    @State private var hasSeenTooltip = false
    @State private var isLoadingTooltipState = true
    @State private var showingTooltip = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Show session-based UI (new)
                    if useSessionView {
                        if sessions.isEmpty && !isLoading {
                            // Placeholder when empty
                            Text("No workout sessions to display")
                                .foregroundColor(.gymtimeTextSecondary)
                                .padding(.top, 40)
                        } else {
                            // Display sessions
                            ForEach(sessions) { session in
                                SessionFeedEntryView(
                                    session: session,
                                    onPropToggle: { sessionId in
                                        Task {
                                            do {
                                                try await toggleSessionProps(for: sessionId)
                                            } catch {
                                                showingError = true
                                                errorMessage = "Failed to update props: \(error.localizedDescription)"
                                                print("❌ Error toggling session props: \(error)")
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            // Load More Button
                            if !isLoading {
                                Button(action: {
                                    Task {
                                        await loadMoreSessions()
                                    }
                                }) {
                                    Text("Load More")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.gymtimeAccent.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }
                    } else {
                        // Original individual workout UI (keep for now)
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
            .simpleTooltip(
                isVisible: showingTooltip,
                title: "Activity Feed",
                message: "This tab shows expandable workout sessions from fellow gymheads.",
                onDismiss: {
                    showingTooltip = false
                    if !hasSeenTooltip {
                        Task {
                            do {
                                let userId = try await supabase.auth.session.user.id
                                try await supabase
                                    .from("profiles")
                                    .update(["has_seen_feed_tooltip": true])
                                    .eq("id", value: userId)
                                    .execute()
                                
                                hasSeenTooltip = true
                            } catch {
                                print("❌ Error updating feed tooltip state: \(error)")
                            }
                        }
                    }
                }
            )
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
                
                // For development: Toggle between old and new UI
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        useSessionView.toggle()
                    } label: {
                        Image(systemName: useSessionView ? "list.bullet" : "list.bullet.rectangle")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingActivityView, onDismiss: {
            // Reset the unread count when activity view is dismissed
            unreadActivityCount = 0
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
                    
                    hasSeenTooltip = profile.hasSeenFeedTooltip
                    isLoadingTooltipState = false
                    
                    if !hasSeenTooltip {
                        print("🔍 First time viewing feed tab - showing tooltip")
                        showingTooltip = true
                    }
                } catch {
                    print("❌ Error loading feed tooltip state: \(error)")
                    isLoadingTooltipState = false
                }
                
                await checkViewStructure()
                await loadWorkouts()
                await fetchUnreadActivityCount()
            }
        }
    }
    
    // MARK: - Temporary Development Methods 
    
    // Create mock data for testing
    private func createMockSessions() {
        print("📱 Creating mock session data")
        
        // Create session 1 with multiple exercises
        let session1 = WorkoutSessionEntry(
            id: "mock-session-1", // Use string ID directly
            userId: "mock-user-1", // Use string ID directly
            userName: "John Smith",
            date: Date(),
            location: "Gym",
            exercises: [
                ExerciseEntry(
                    id: UUID(),
                    exerciseName: "Bench Press",
                    weight: 225,
                    sets: 4,
                    reps: 8,
                    achievement: "225lbs • 4×8",
                    originalWorkoutId: UUID()
                ),
                ExerciseEntry(
                    id: UUID(),
                    exerciseName: "Incline DB Press",
                    weight: 70,
                    sets: 3,
                    reps: 10,
                    achievement: "70lbs • 3×10",
                    originalWorkoutId: UUID()
                )
            ],
            propsCount: 4,
            isProppedByCurrentUser: true,
            workoutSummary: nil
        )
        
        // Create session 2 with a single exercise
        let session2 = WorkoutSessionEntry(
            id: "mock-session-2", // Use string ID directly
            userId: "mock-user-2", // Use string ID directly
            userName: "Emma Johnson",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            location: "Home Gym",
            exercises: [
                ExerciseEntry(
                    id: UUID(),
                    exerciseName: "Pullups",
                    weight: nil,
                    sets: 3,
                    reps: 12,
                    achievement: "3×12",
                    originalWorkoutId: UUID()
                )
            ],
            propsCount: 2,
            isProppedByCurrentUser: false,
            workoutSummary: nil
        )
        
        // Add sessions to the state
        self.sessions = [session1, session2]
    }
    
    // MARK: - Session Props Logic
    
    /// Toggles props for a workout session and saves to Supabase
    private func toggleSessionProps(for sessionId: String) async throws {
        // Update local state first for responsive UI
        let isRemoving = proppedSessions.contains(sessionId)
        
        if isRemoving {
            proppedSessions.remove(sessionId)
            // Find and update the session in our list
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[index].propsCount = max(0, sessions[index].propsCount - 1)
                sessions[index].isProppedByCurrentUser = false
            }
        } else {
            proppedSessions.insert(sessionId)
            // Find and update the session in our list
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[index].propsCount += 1
                sessions[index].isProppedByCurrentUser = true
            }
        }
        
        // Check if user is logged in and get their ID
        let authSession = await supabase.auth.session
        let userId = authSession.user.id.uuidString.lowercased() // Always store lowercase user IDs for consistency
        
        // Define the structure for session props
        struct SessionProp: Codable {
            let session_id: String
            let user_id: String
        }
        
        if isRemoving {
            // Remove prop from database
            _ = try await supabase
                .from("workout_session_props")
                .delete()
                .eq("session_id", value: sessionId)
                .eq("user_id", value: userId)
                .execute()
            
            print("📱 Removed props for session: \(sessionId)")
        } else {
            // Add prop to database
            _ = try await supabase
                .from("workout_session_props")
                .insert(
                    SessionProp(
                        session_id: sessionId,
                        user_id: userId
                    )
                )
                .execute()
            
            print("📱 Added props for session: \(sessionId)")
        }
    }
    
    // MARK: - Existing Methods (unchanged)
    
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
        
        // Fetch workout sessions if we're using the new UI
        if useSessionView {
            do {
                print("🔍 Loading workout sessions from database")
                
                // Define decodable struct to match the database structure
                struct WorkoutSessionData: Decodable {
                    let id: String
                    let user_id: String
                    let username: String?
                    let full_name: String?
                    let date: String  // We'll parse this into Date later
                    let location: String?
                    let exercise_count: Int
                    let exercises: [ExerciseData]
                    let primary_exercise: String?
                    let workout_summary: String?  // Add this new field
                    
                    struct ExerciseData: Decodable, Identifiable {
                        let id: String
                        let exercise: String
                        let weight: Double?
                        let sets: Int?
                        let reps: Int?
                    }
                }
                
                // 1. Fetch sessions from the workout_sessions table
                let response: [WorkoutSessionData] = try await supabase
                    .from("workout_sessions")
                    .select()
                    .not("username", operator: .is, value: "null")
                    .order("date", ascending: false)
                    .range(from: sessionsOffset, to: sessionsOffset + 9)
                    .execute()
                    .value
                
                print("🔍 Fetched \(response.count) workout sessions")
                
                // 2. Convert to our UI model
                var sessionEntries = response.map { sessionData in
                    // Create exercise entries
                    let exercises = sessionData.exercises.map { exerciseData in
                        ExerciseEntry(
                            id: UUID(uuidString: exerciseData.id) ?? UUID(),
                            exerciseName: exerciseData.exercise,
                            weight: exerciseData.weight,
                            sets: exerciseData.sets,
                            reps: exerciseData.reps,
                            achievement: formatExerciseAchievement(weight: exerciseData.weight, sets: exerciseData.sets, reps: exerciseData.reps),
                            originalWorkoutId: UUID(uuidString: exerciseData.id) ?? UUID()
                        )
                    }
                    
                    return WorkoutSessionEntry(
                        id: sessionData.id, // Use string ID directly
                        userId: sessionData.user_id, // Use string ID directly
                        userName: sessionData.username?.isEmpty == true ? (sessionData.full_name ?? "User") : sessionData.username ?? "User",
                        date: createISO8601DateFormatter().date(from: sessionData.date) ?? Date(),
                        location: sessionData.location ?? "Gym",
                        exercises: exercises,
                        propsCount: 0,
                        isProppedByCurrentUser: false,
                        workoutSummary: sessionData.workout_summary
                    )
                }
                
                // 3. Fetch prop counts for these sessions
                if !sessionEntries.isEmpty {
                    // Get current user ID to check if they've propped any sessions
                    let authSession = await supabase.auth.session
                    let currentUserId = authSession.user.id.uuidString
                    
                    // Get all session IDs
                    let sessionIds = sessionEntries.map { $0.id }
                    print("🔍 Fetching props for \(sessionIds.count) sessions")
                    
                    // Fetch props for these sessions
                    struct SessionPropData: Decodable {
                        let session_id: String
                        let user_id: String
                    }
                    
                    do {
                        let sessionProps: [SessionPropData] = try await supabase
                            .from("workout_session_props")
                            .select("session_id, user_id")
                            .execute()
                            .value
                        
                        print("🔍 Found \(sessionProps.count) total session props")
                        
                        // Add extensive debug logging
                        print("🔎 DEBUG: ---- ID FORMAT COMPARISON ----")
                        if let firstProp = sessionProps.first {
                            print("🔎 DEBUG: DB Prop session_id: \"\(firstProp.session_id)\"")
                            print("🔎 DEBUG: DB Prop user_id: \"\(firstProp.user_id)\"")
                        }
                        
                        if let firstSessionId = sessionIds.first {
                            print("🔎 DEBUG: UI session_id: \"\(firstSessionId)\"")
                            print("🔎 DEBUG: UI current user_id: \"\(currentUserId)\"")
                        }
                        
                        print("🔎 DEBUG: All session IDs in UI:")
                        for (index, id) in sessionIds.enumerated() {
                            print("🔎 DEBUG:   [\(index)]: \"\(id)\"")
                        }
                        
                        print("🔎 DEBUG: All prop session IDs from DB:")
                        for (index, prop) in sessionProps.enumerated() {
                            if index < 5 { // Just show first 5 to avoid log spam
                                print("🔎 DEBUG:   [\(index)]: \"\(prop.session_id)\"")
                            }
                        }
                        print("🔎 DEBUG: Session ID direct matches test:")
                        for prop in sessionProps.prefix(3) {
                            print("🔎 DEBUG:   Prop \(prop.session_id) exists in UI sessions: \(sessionIds.contains(prop.session_id))")
                        }
                        print("🔎 DEBUG: ---- END ID FORMAT COMPARISON ----")
                        
                        // SIMPLIFIED APPROACH: Work directly with the string IDs without normalization
                        var propCountsBySession: [String: Int] = [:]
                        var sessionsProppedByUser: Set<String> = []
                        
                        // Process each prop
                        for prop in sessionProps {
                            // Check if this prop's session ID matches any of our sessions directly
                            if sessionIds.contains(prop.session_id) {
                                // Found a match - increment count
                                propCountsBySession[prop.session_id, default: 0] += 1
                                
                                // Check if current user has propped this session
                                // Use case-insensitive comparison for user IDs
                                if prop.user_id.lowercased() == currentUserId.lowercased() {
                                    sessionsProppedByUser.insert(prop.session_id)
                                    print("🔎 DEBUG: Session \(prop.session_id) is propped by current user (matched \(prop.user_id) with \(currentUserId))")
                                } else {
                                    print("🔎 DEBUG: User ID comparison - DB: \(prop.user_id.lowercased()) vs Current: \(currentUserId.lowercased())")
                                }
                            }
                        }
                        
                        print("🔍 Counted props for \(propCountsBySession.count) sessions")
                        if propCountsBySession.count > 0 {
                            print("🔎 DEBUG: Found props for these sessions:")
                            for (sessionId, count) in propCountsBySession {
                                print("🔎 DEBUG:   Session \(sessionId): \(count) props")
                            }
                        }
                        
                        // Update session entries with prop counts
                        for i in 0..<sessionEntries.count {
                            let sessionId = sessionEntries[i].id
                            
                            // Direct lookup using the original session ID
                            if let count = propCountsBySession[sessionId] {
                                sessionEntries[i].propsCount = count
                                print("🔎 DEBUG: Updated session \(sessionId) with \(count) props")
                            }
                            
                            // Check if user has propped this session
                            sessionEntries[i].isProppedByCurrentUser = sessionsProppedByUser.contains(sessionId)
                            
                            // Update local tracking state to match database
                            if sessionEntries[i].isProppedByCurrentUser {
                                proppedSessions.insert(sessionId)
                                print("🔎 DEBUG: Session \(sessionId) is propped by current user")
                            }
                        }
                    } catch {
                        print("❌ Error fetching session props: \(error)")
                        // Continue with the sessions we have, just without accurate prop counts
                    }
                }
                
                // Update state - append new sessions if we're loading more, otherwise replace
                if sessionsOffset > 0 {
                    sessions.append(contentsOf: sessionEntries)
                } else {
                    sessions = sessionEntries
                }
                
            } catch {
                showingError = true
                errorMessage = "Failed to load workout sessions: \(error.localizedDescription)"
                print("❌ Error loading workout sessions: \(error)")
            }
            return
        }
        
        // Original code for individual workouts below
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
                        workoutId: workoutId.uuidString,
                        userId: userId.uuidString
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
    
    // Helper function to format exercise achievement
    private func formatExerciseAchievement(weight: Double?, sets: Int?, reps: Int?) -> String {
        var parts: [String] = []
        
        if let weight = weight {
            parts.append("\(Int(weight))lbs")
        }
        
        if let sets = sets, let reps = reps {
            parts.append("\(sets)×\(reps)")
        }
        
        return parts.isEmpty ? "Completed exercise" : parts.joined(separator: " • ")
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
                let dateString = createISO8601DateFormatter().string(from: lastRead)
                
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
    
    private func loadMoreSessions() async {
        sessionsOffset += 10
        await loadWorkouts()
    }
    
    // Add a helper function for consistent ISO8601 date formatting
    private func createISO8601DateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

// MARK: - Preview
#Preview {
    FeedView()
}

// MARK: - Models

// MARK: - Current Individual Workout Model
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

// MARK: - New Session-Based Models

/// Model representing a single exercise within a workout session
struct ExerciseEntry: Identifiable {
    let id: UUID
    let exerciseName: String
    let weight: Double?
    let sets: Int?
    let reps: Int?
    let achievement: String // Formatted achievement text (e.g. "200lbs • 3×10")
    let originalWorkoutId: UUID // Reference to the original workout entry
    
    // Computed property to display formatted stats
    var displayStats: String {
        var parts: [String] = []
        
        if let weight = weight {
            parts.append("\(Int(weight))lbs")
        }
        
        if let sets = sets, let reps = reps {
            parts.append("\(sets)×\(reps)")
        }
        
        return parts.isEmpty ? "Completed exercise" : parts.joined(separator: " • ")
    }
}

/// Model representing a grouped workout session in the feed
struct WorkoutSessionEntry: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let date: Date
    let location: String
    var exercises: [ExerciseEntry]
    var propsCount: Int = 0 // Total props for all exercises in this session
    var isProppedByCurrentUser: Bool = false
    let workoutSummary: String?  // Add this new field
    
    // Computed properties
    var exerciseCount: Int {
        exercises.count
    }
    
    // Get the "hero" exercise to highlight (most impressive or challenging)
    var primaryExercise: ExerciseEntry? {
        // For now, just return the first exercise
        // In the future, we could implement more complex logic to determine
        // which exercise is most impressive based on weight, PR status, etc.
        return exercises.first
    }
    
    // Summary text for the workout session
    var summary: String {
        if exercises.count == 1 {
            return "1 exercise"
        } else {
            return "\(exercises.count) exercises"
        }
    }
}

/// Model for sending workout props to Supabase
struct WorkoutProp: Codable {
    let workout_id: String
    let user_id: String
    
    // Updated initializer to accept String IDs
    init(workoutId: String, userId: String) {
        self.workout_id = workoutId
        self.user_id = userId
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
                // Since we're not tracking read status in this simplified version,
                // we just dismiss the view
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
    
    // Modified to implement the simplified approach with enhanced logging
    private func loadActivity() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current user's ID
            let session = await supabase.auth.session
            let currentUserId = session.user.id.uuidString.lowercased()
            
            print("🔍 Loading activity: Getting sessions for user \(currentUserId)")
            
            // STEP 1: Get all sessions owned by current user (no time filter)
            struct SessionInfo: Decodable {
                let id: String
                let primary_exercise: String?
                let exercise_count: Int?
                let date: String // Include the date field
            }
            
            let userSessions: [SessionInfo] = try await supabase
                .from("workout_sessions")
                .select("id, primary_exercise, exercise_count, date")
                .eq("user_id", value: currentUserId)
                .execute()
                .value
            
            // Get just the IDs for the next query
            let sessionIds = userSessions.map { $0.id }
            print("🔍 Found \(sessionIds.count) sessions for this user")
            
            if !sessionIds.isEmpty {
                print("🔍 First few session IDs:")
                for (index, id) in sessionIds.prefix(3).enumerated() {
                    print("🔍   Session [\(index)]: \(id)")
                }
            }
            
            if sessionIds.isEmpty {
                // No sessions, no notifications
                print("🔍 No sessions found, skipping prop check")
                self.activities = []
                unreadCount = 0
                return
            }
            
            // STEP 2: Get all props for those sessions
            struct SessionProp: Decodable {
                let session_id: String
                let user_id: String
                let created_at: String
            }
            
            let sessionProps: [SessionProp] = try await supabase
                .from("workout_session_props")
                .select("session_id, user_id, created_at")
                .in("session_id", values: sessionIds)
                .order("created_at", ascending: false) // Newest first
                .execute()
                .value
            
            print("🔍 Found \(sessionProps.count) props for these sessions")
            
            if !sessionProps.isEmpty {
                print("🔍 First few props details:")
                for (index, prop) in sessionProps.prefix(3).enumerated() {
                    print("🔍   Prop [\(index)]: session_id=\(prop.session_id), user_id=\(prop.user_id), created_at=\(prop.created_at)")
                }
            }
            
            if sessionProps.isEmpty {
                // No props, no notifications
                self.activities = []
                unreadCount = 0
                return
            }
            
            // STEP 3: Get user info for prop givers
            let propUserIds = Array(Set(sessionProps.map { $0.user_id }))
            print("🔍 Unique user IDs giving props: \(propUserIds)")
            
            struct UserInfo: Decodable {
                let id: String
                let username: String?
                let full_name: String?
            }
            
            let userInfos: [UserInfo] = try await supabase
                .from("profiles") // Using profiles table
                .select("id, username, full_name")
                .in("id", values: propUserIds)
                .execute()
                .value
            
            print("🔍 Found user info for \(userInfos.count) users")
            
            if !userInfos.isEmpty {
                print("🔍 User info details:")
                for (index, user) in userInfos.prefix(4).enumerated() {
                    print("🔍   User [\(index)]: id=\(user.id), username=\(user.username ?? "nil"), full_name=\(user.full_name ?? "nil")")
                }
            }
            
            // Create dictionaries for faster lookups
            let sessionDetailsDict = Dictionary(uniqueKeysWithValues: 
                userSessions.map { ($0.id, $0) })
            let userInfoDict = Dictionary(uniqueKeysWithValues: 
                userInfos.map { ($0.id.lowercased(), $0) }) // Use lowercase keys for case-insensitive lookup
            
            print("🔍 Created lookup dictionaries: sessions=\(sessionDetailsDict.count), users=\(userInfoDict.count)")
            
            // STEP 4: Create activity items directly (no grouping in this simplified version)
            var activityItems: [ActivityItem] = []
            
            // Track the success/failure for each prop processing
            var successfulProps = 0
            var dateParsingFailures = 0
            var userInfoMissing = 0
            var sessionInfoMissing = 0
            
            for (index, prop) in sessionProps.enumerated() {
                print("🔍 Processing prop \(index): session_id=\(prop.session_id), user_id=\(prop.user_id)")
                
                // Check date parsing
                // Create a properly configured ISO8601DateFormatter that handles fractional seconds
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                guard let propDate = dateFormatter.date(from: prop.created_at) else {
                    print("❌ Failed to parse date: \(prop.created_at)")
                    dateParsingFailures += 1
                    continue
                }
                
                // Check user info
                let userInfoLookupId = prop.user_id.lowercased()
                guard let userInfo = userInfoDict[userInfoLookupId] else {
                    print("❌ No user info found for ID: \(userInfoLookupId)")
                    print("❌ Available user IDs in dict: \(userInfoDict.keys.joined(separator: ", "))")
                    userInfoMissing += 1
                    continue
                }
                
                let propUserName = userInfo.username?.isEmpty == true ? 
                                  (userInfo.full_name ?? "User") : 
                                  userInfo.username ?? "User"
                
                // Check session info
                guard let sessionInfo = sessionDetailsDict[prop.session_id] else {
                    print("⚠️ No session info found for ID: \(prop.session_id)")
                    sessionInfoMissing += 1
                    continue
                }
                
                // Format the date for display
                var formattedDate = "workout"
                if let sessionDate = {
                    // Create a properly configured ISO8601DateFormatter
                    let iso8601Formatter = ISO8601DateFormatter()
                    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return iso8601Formatter.date(from: sessionInfo.date)
                }() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .none
                    formattedDate = dateFormatter.string(from: sessionDate)
                }
                
                // Create the activity item with the date in the message
                let activityItem = ActivityItem(
                    id: UUID(),
                    type: .receivedProps,
                    userName: propUserName,
                    userAvatar: String(propUserName.prefix(1).uppercased()),
                    content: "\(propUserName) gave props for your \(formattedDate) workout",
                    timestamp: propDate,
                    isRead: false, // Not using this in the simplified version
                    relatedId: prop.session_id
                )
                
                activityItems.append(activityItem)
                successfulProps += 1
                print("✅ Created activity item: \(activityItem.content)")
            }
            
            print("🔍 Processing summary: Total props=\(sessionProps.count), Successful=\(successfulProps), Date failures=\(dateParsingFailures), Missing user info=\(userInfoMissing), Missing session info=\(sessionInfoMissing)")
            
            // STEP 5: Update UI state
            self.activities = activityItems
            
            // In this simplified version, we'll just set the unread count
            // to the total number of activities for the badge in the main view
            unreadCount = activityItems.count
            
            print("🔍 Displaying \(activityItems.count) activity items")
            
        } catch {
            showingError = true
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            print("❌ Error loading activities: \(error)")
            print("❌ Detailed error: \(String(describing: error))")
        }
    }
    
    // Since we're not tracking read status in this simplified version,
    // we've removed the markAllAsRead function
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