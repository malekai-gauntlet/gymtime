### 1. Project Overview: Gymtime

#### 1.1 Opportunity
1. Manually tracking gym workouts using sheets or existing apps (e.g., Fitbod) is tedious.  
2. A voice-based solution combined with social engagement (à la Strava) saves time and adds motivation.

#### 1.2 Validation
1. Self-validation and strong interest expressed by friends confirm demand.

#### 1.3 Target User
1. **One-liner:** Analytical fitness enthusiast tired of manual workout logging.  
2. **Demographic:** 22-35-year-old males in big cities, frequenting top gyms (e.g., Gold’s, Equinox, LifeTime).  
3. **Psychographic:** Busy, tech-savvy, data-driven, goal-oriented, and Type-A.

#### 1.4 Branding
1. **App Name:** gymtime  
2. **Slogan:** Log workouts faster with Voice AI

#### 1.5 User Stories
1. I want to log my workout by speaking so it’s recorded automatically.  
2. I want to edit my logged workouts for accuracy.  
3. I want to duplicate past workouts with one tap.  
4. I want AI to flag imbalances or overuse injuries and suggest counter exercises.  
5. I want a summary view of my workouts and progress.  
6. I want a social feed (similar to Venmo) showing friends’ workouts.  
7. I want integration with devices like Whoop/Oura/Apple Watch for comprehensive metrics.  
8. I want to upload photos to my workouts for visual progress tracking.  
9. I want leaderboards that rank users by total weight lifted over defined periods.

#### 1.6 ITD
1. **Tech Stack:** Swift iOS with SwiftUI, Supabase + Edge Functions.  
2. **Open Source Diff:** Start from a basic SwiftUI template and build out.

---

### 2. Technical Requirements

#### 2.1 Data Models and Relationships
1. **User Model:**  
   - **Fields:** `id (UUID)`, `username`, `email`, `passwordHash`, `fullName`, `profileImageURL (optional)`, `createdAt`, `updatedAt`.  
   - **Relationships:** Each User has many Workouts, HealthMetrics, Friendships, and Comments.

2. **Workout Model:**  
   - **Fields:** `id (UUID)`, `userId (FK)`, `date`, `duration`, `voiceTranscript`, `notes`, `duplicateOfWorkoutId (optional)`, `createdAt`, `updatedAt`.  
   - **Relationships:** Each Workout belongs to a User and has many Exercises, Photos, and Comments.

3. **Exercise Model:**  
   - **Fields:** `id (UUID)`, `workoutId (FK)`, `name`, `muscleGroup` (to specify target muscle groups), `sets`, `reps`, `weight`, `bodyweight (optional)`, `tempo (optional)`, `notes`, and an `order` field.  
   - **Relationships:** Each Exercise belongs to a Workout.

4. **Photo Model:**  
   - **Fields:** `id (UUID)`, `workoutId (FK)`, `imageURL`, `caption (optional)`, `createdAt`.  
   - **Relationships:** Each Photo belongs to a Workout.

5. **HealthMetric Model:**  
   - **Fields:** `id (UUID)`, `userId (FK)`, `source` (e.g., Apple Watch), `metricType`, `value`, `recordedAt`.  
   - **Relationships:** Each HealthMetric belongs to a User.

6. **Friendship Model:**  
   - **Fields:** `id (UUID)`, `userId (FK)`, `friendId (FK)`, `status` (e.g., pending, accepted), `createdAt`.  
   - **Relationships:** Connects two Users.

7. **Comment Model:**  
   - **Fields:** `id (UUID)`, `userId (FK)`, `workoutId (FK)`, `content`, `createdAt`.  
   - **Relationships:** Each Comment belongs to a User and a Workout.

8. **LeaderboardEntry Model:**  
   - **Fields:** `id (UUID)`, `userId (FK)`, `period` (e.g., weekly, monthly), `totalWeightLifted`, `rank`, `calculatedAt`.  
   - **Relationships:** Each LeaderboardEntry belongs to a User.

#### 2.2 Core Functionality Requirements
1. Enable voice-based workout logging that converts speech to text and creates a Workout along with parsed Exercises.  
2. Allow users to log workouts with fields similar to a sheet or Fitbod entry—specifically capturing date, workout name, muscle group, notes, weight, bodyweight, sets, and reps.  
3. Enable editing of workouts and individual exercises for corrections.  
4. Implement a duplication feature that clones a previous Workout, including its Exercises and Photos.  
5. Provide a social feed displaying friends’ workouts with options to comment and like posts.  
6. Integrate with wearable devices and HealthKit to automatically import HealthMetric data.  
7. Run AI analysis on workout patterns to flag imbalances or overuse risks and recommend counter exercises.  
8. Support photo uploads to enable visual progress tracking.  
9. Create leaderboards that aggregate total weight lifted over defined periods and rank users accordingly.

#### 2.3 Authorization Requirements
1. Enforce secure user authentication using Supabase Auth and tokens for all data access and modification endpoints.  
2. Restrict users to accessing and editing only their own Workouts, HealthMetrics, and related logs, while allowing public read access for social feed posts.  
3. Apply row-level security so that Friendships, Comments, and LeaderboardEntries are visible only to authorized users.  
4. Require explicit user consent before integrating external health data and processing voice recordings.

---

### 3. UI / Functionality Inspiration
1. **Workout Logging & Design:** Leverage Fitbod’s clean, data-centric design and intuitive logging interface for both manual and voice-based entries.  
2. **Community Aspect:** Draw inspiration from Strava’s social feed, user interactions, and gamified challenges to encourage competition and engagement.  
3. **Overall UI:** Emphasize minimalistic, intuitive SwiftUI layouts that integrate seamlessly with voice input and data visualization.

---

### 4. System Architecture

#### 4.1 API Routes with HTTP Methods and Auth Requirements
1. **User Routes:**  
   - **POST /users:** Create a new user account (public, Supabase Auth handles registration).  
   - **GET /users/:id:** Retrieve user profile (authentication required; users can access their own profile, limited public info otherwise).  
   - **PUT /users/:id:** Update user profile details (authentication required).  
   - **DELETE /users/:id:** Delete a user account (authentication required).

2. **Workout Routes:**  
   - **GET /workouts:** Retrieve a list of workouts (authentication required for personal workouts; public feed for community view).  
   - **GET /workouts/:id:** Retrieve details of a specific workout (authentication required for owner; public view for social feed posts).  
   - **POST /workouts:** Create a new workout with fields like date, workout name, muscle group, notes, weight, bodyweight, sets, and reps (authentication required).  
   - **PUT /workouts/:id:** Update an existing workout (authentication required).  
   - **DELETE /workouts/:id:** Delete a workout (authentication required).

3. **Exercise Routes:**  
   - **GET /workouts/:workoutId/exercises:** List exercises for a specific workout (authentication required).  
   - **POST /workouts/:workoutId/exercises:** Create a new exercise entry (authentication required).  
   - **PUT /exercises/:id:** Update an exercise (authentication required).  
   - **DELETE /exercises/:id:** Delete an exercise (authentication required).

4. **Photo Routes:**  
   - **GET /workouts/:workoutId/photos:** List photos attached to a workout (authentication required).  
   - **POST /workouts/:workoutId/photos:** Upload a new photo (authentication required).  
   - **DELETE /photos/:id:** Delete a photo (authentication required).

5. **HealthMetric Routes:**  
   - **GET /healthmetrics:** List health metrics for the authenticated user (authentication required).  
   - **POST /healthmetrics:** Create or import new health metric data (authentication required, typically triggered by HealthKit integrations).  
   - **DELETE /healthmetrics/:id:** Remove a health metric entry (authentication required).

6. **Friendship Routes:**  
   - **GET /friendships:** Retrieve the list of friendships for the authenticated user (authentication required).  
   - **POST /friendships:** Send a friendship request (authentication required).  
   - **PUT /friendships/:id:** Update the status of a friendship (authentication required).  
   - **DELETE /friendships/:id:** Remove a friendship (authentication required).

7. **Comment Routes:**  
   - **GET /workouts/:workoutId/comments:** List comments for a workout (authentication required for posting; public for viewing when permitted).  
   - **POST /workouts/:workoutId/comments:** Create a new comment (authentication required).  
   - **PUT /comments/:id:** Update a comment (authentication required).  
   - **DELETE /comments/:id:** Delete a comment (authentication required).

8. **Leaderboard Routes:**  
   - **GET /leaderboards/:period:** Retrieve leaderboard entries for a specific period (public read access).  
   - **GET /leaderboards/user/:userId:** Retrieve leaderboard data for a user (authentication required for detailed personal stats).  
   - **POST /leaderboards/calculate:** Trigger leaderboard recalculation (restricted to admin or internal use).

#### 4.2 Page Structure and Components Needed
1. **Authentication Pages:**  
   - **Login/Signup Pages:** Include forms for email/password registration and login integrated with Supabase Auth.
2. **Home Feed Page:**  
   - **Components:** Navigation Bar, WorkoutFeed (list of WorkoutCards), and a floating action button for new workout logging.
3. **Workout Logging Page:**  
   - **Components:** VoiceInput module, manual input form (fields for date, workout name, muscle group, notes, weight, bodyweight, sets, reps), and submission button.
4. **Workout Detail & Edit Page:**  
   - **Components:** Detailed Workout view with ExerciseList, PhotoGallery, CommentSection, and Edit functionality for each section.
5. **Profile Page:**  
   - **Components:** User information display, personal workout history, friend requests/relationships, and settings access.
6. **Community Page:**  
   - **Components:** Social feed styled like Strava’s activity stream, with options to like, comment, and view friend workouts.
7. **Leaderboard Page:**  
   - **Components:** LeaderboardList showing user rankings with total weight lifted and period filters.
8. **Settings/Integration Page:**  
   - **Components:** Options to connect with HealthKit/wearable devices and manage account preferences.

#### 4.3 Key Middleware Functions and Auth Flows
1. **Authentication Middleware:**  
   - Validates Supabase Auth tokens on all protected endpoints, ensuring that only authenticated requests are processed.
2. **Authorization Middleware:**  
   - Enforces that users can only access or modify their own resources (e.g., workouts, exercises, comments) and applies row-level security.
3. **Validation Middleware:**  
   - Checks request bodies for required fields and correct data types for each model (e.g., ensuring proper numeric inputs for sets and reps).
4. **Error Handling Middleware:**  
   - Catches errors across API routes and returns standardized error messages with proper HTTP status codes.
5. **Logging Middleware:**  
   - Logs API requests and responses for debugging and performance monitoring.
6. **Key Auth Flows:**  
   - **Registration Flow:** User registers via the Signup Page; Supabase Auth creates the account and returns a token.  
   - **Login Flow:** User logs in; token is issued and attached to subsequent API requests via headers.  
   - **Protected Endpoint Flow:** Each API call checks the token via the Authentication Middleware, then applies Authorization Middleware to confirm the user’s access rights.  
   - **Token Refresh Flow:** Automatically refresh tokens when nearing expiration using Supabase’s built-in refresh mechanism.

---

### 5. Documentation Resources

1. **Supabase Documentation:**  
   - Supabase Overview & Guides: [https://supabase.com/docs](https://supabase.com/docs) citeturn0search0  
   - Supabase Auth: [https://supabase.com/docs/guides/auth](https://supabase.com/docs/guides/auth) citeturn0search0  
   - Supabase Edge Functions: [https://supabase.com/docs/guides/functions](https://supabase.com/docs/guides/functions) citeturn0search0  
   - Supabase Row Level Security: [https://supabase.com/docs/guides/database/row-level-security](https://supabase.com/docs/guides/database/row-level-security) citeturn0search0

2. **Swift & SwiftUI Documentation:**  
   - Swift Programming Language Guide: [https://docs.swift.org/swift-book/](https://docs.swift.org/swift-book/) citeturn0search0  
   - Swift.org Documentation: [https://swift.org/documentation/](https://swift.org/documentation/) citeturn0search0  
   - SwiftUI Documentation (Apple): [https://developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui) citeturn0search0  
   - SwiftUI Tutorials (Apple): [https://developer.apple.com/tutorials/swiftui](https://developer.apple.com/tutorials/swiftui) citeturn0search0

3. **iOS Development & HealthKit:**  
   - iOS Developer Documentation: [https://developer.apple.com/ios/](https://developer.apple.com/ios/) citeturn0search0  
   - General Apple Developer Documentation: [https://developer.apple.com/documentation](https://developer.apple.com/documentation) citeturn0search0  
   - HealthKit Documentation: [https://developer.apple.com/documentation/healthkit](https://developer.apple.com/documentation/healthkit) citeturn0search0  
   - HealthKit Integration Guide: [https://developer.apple.com/documentation/healthkit/creating_a_healthkit_app](https://developer.apple.com/documentation/healthkit/creating_a_healthkit_app) citeturn0search0

4. **Voice Recognition / Speech Framework:**  
   - Apple Speech Framework: [https://developer.apple.com/documentation/speech](https://developer.apple.com/documentation/speech) citeturn0search0

5. **Additional iOS Integration:**  
   - Supabase iOS SDK Documentation: [https://supabase.com/docs/reference/ios](https://supabase.com/docs/reference/ios) citeturn0search0
