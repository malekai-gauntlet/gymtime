# Anonymous User Conversion Feature

## Overview
To prevent data loss for anonymous users, we'll implement a prompt to convert their account after logging 3 workouts.

## Implementation Progress

✅ COMPLETED:
1. Created `AnonymousConversionView` with:
   - Clean UI for email/password input
   - Benefits section explaining why to convert
   - Save Account and Maybe Later buttons
   - Error handling states

2. Added anonymous user detection:
   - Added `isAnonymous` flag to `ProfileViewModel`
   - Updated `loadUserProfile()` to set anonymous status
   - Modified edit button in `ProfileView` to show different icon and behavior for anonymous users

🚧 IN PROGRESS:
1. **Track Workout Count**
   - Add workout counter in Supabase for each user
   - Increment counter after each successful workout save
   - Query this count when needed

⏳ TODO:
1. **Add Conversion Logic**
   - Check workout count after each workout save
   - If count reaches 3 and user is anonymous:
     - Show conversion modal
     - Convert anonymous account to permanent
     - Preserve all existing workout data

2. **Database Updates**
   ```sql
   -- Add to users table
   alter table users
   add column workout_count integer default 0,
   add column has_seen_conversion_prompt boolean default false;
   ```

3. **Implementation Details**

   a. After each workout save:
   ```swift
   func incrementWorkoutCount() async {
       // Increment workout_count in Supabase
       // Check if should show conversion prompt
   }
   ```

   b. Conversion logic:
   ```swift
   func convertAnonymousAccount(email: String, password: String) async {
       // Convert Firebase anonymous account to permanent
       // Update Supabase user record
   }
   ```

4. **Error Handling**
   - Handle network connectivity issues
   - Provide retry options for failed conversions
   - Preserve local data during conversion process

5. **Testing Scenarios**
   - Anonymous user flow
   - Conversion process
   - Data preservation
   - Edge cases (network issues, app termination during conversion)

## Current User Flow

## Implementation Steps

1. **Track Workout Count**
   - Add a workout counter in Supabase for each user
   - Increment counter after each successful workout save
   - Query this count when needed

2. **Create Conversion Modal View**
   ```swift
   struct AccountConversionView: View {
       // Display benefits of account conversion
       // Email/password input fields
       // Convert account button
       // "Maybe Later" option
   }
   ```

3. **Add Conversion Logic**
   - Check workout count after each workout save
   - If count reaches 3 and user is anonymous:
     - Show conversion modal
     - Convert anonymous account to permanent
     - Preserve all existing workout data

4. **User Flow**
   ```
   Anonymous User
   └── Logs 3 workouts
       ├── Shows conversion modal
       │   ├── User converts (Add email/password)
       │   │   └── Continue with permanent account
       │   └── User clicks "Maybe Later"
       │       └── Remind again after 3 more workouts
   ```

5. **Database Updates**
   ```sql
   -- Add to users table
   alter table users
   add column workout_count integer default 0,
   add column has_seen_conversion_prompt boolean default false;
   ```

6. **Implementation Details**

   a. After each workout save:
   ```swift
   func incrementWorkoutCount() async {
       // Increment workout_count in Supabase
       // Check if should show conversion prompt
   }
   ```

   b. Conversion logic:
   ```swift
   func convertAnonymousAccount(email: String, password: String) async {
       // Convert Firebase anonymous account to permanent
       // Update Supabase user record
   }
   ```

7. **Error Handling**
   - Handle network connectivity issues
   - Provide retry options for failed conversions
   - Preserve local data during conversion process

8. **Testing Scenarios**
   - Anonymous user flow
   - Conversion process
   - Data preservation
   - Edge cases (network issues, app termination during conversion)