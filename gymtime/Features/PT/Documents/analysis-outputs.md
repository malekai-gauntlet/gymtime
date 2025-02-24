# Workout Analysis Data Structure

## WorkoutAnalysis Instance
Main container for all analysis results.

### Core Metrics
- `pushPullRatio: Double`
  - Ratio between push and pull exercises
  - 1.0 means perfect balance
  - >1.0 means more push than pull
  - <1.0 means more pull than push
  - Considered balanced between 0.8 and 1.2

### Muscle Groups Status
Dictionary of muscle group statuses: `[String: MuscleGroupStatus]`

For each muscle group (chest, back, shoulders, biceps, triceps, legs, core):
- `trainingCount: Int`
  - Number of times trained in analysis period
- `lastWorkoutDate: Date?`
  - Date of most recent workout
- `strengthScore: Double`
  - 0-100 score calculated from:
    - Frequency (40%): How often you train
    - Volume (40%): Weight × Sets × Reps
    - Consistency (20%): Workout spacing

### Warnings Array
Array of warning messages triggered by:
- Push/pull imbalances (>1.5 or <0.67 ratio)
- Neglected muscle groups (0 workouts)
- Extended gaps (>7 days without training)
- Overtraining (>15 workouts in 30 days)

Example warnings:
- "Your training favors push exercises significantly over pull exercises"
- "Back hasn't been trained in over a week"
- "Potential overtraining of chest"
- "Legs appears to be completely neglected"

### Recommendations Array
Actionable suggestions based on warnings:
- "Include more pulling movements (rows, pull-ups) in your routine"
- "Schedule a legs workout soon"
- "Consider reducing chest training frequency"
- "Add core exercises to your routine"

### Helper Properties
- `hasWarnings: Bool`
  - True if any warnings exist
- `hasRecommendations: Bool`
  - True if any recommendations exist
- `isPushPullBalanced: Bool`
  - True if ratio is between 0.8-1.2
- `needsAttention(muscleGroup: String) -> Bool`
  - True if muscle group hasn't been trained in 7 days

### Analysis Metadata
- `analysisDate: Date`
  - When analysis was performed
- `daysAnalyzed: Int`
  - Time period analyzed (default 30)

## Calculation Details

### Strength Score Components
1. Frequency Score (0-40 points)
   - Based on training frequency relative to optimal
   - Caps at 40 points (roughly 4 sessions per muscle group)

2. Volume Score (0-40 points)
   - Calculated from total volume (weight × sets × reps)
   - Normalized by analysis timeframe
   - Caps at 40 points

3. Consistency Score (0-20 points)
   - Based on workout spacing
   - Optimal gap is 3-4 days between sessions
   - Score decreases for too frequent or too sparse training

### Push/Pull Classification
Exercises are classified as:
- Push: chest, shoulders (without back), triceps (without back)
- Pull: back, biceps
- Other: legs, core

Some exercises (like face pulls) count for both categories based on muscle involvement.

## Available Data for UI Display
1. Overall Status:
   - Push/pull balance
   - General training consistency
   - Immediate attention needs

2. Per Muscle Group:
   - Strength score
   - Training frequency
   - Last workout date
   - Need for attention

3. Action Items:
   - Prioritized warnings
   - Specific recommendations
   - Training adjustments needed

4. Progress Indicators:
   - Strength scores (0-100)
   - Balance ratios
   - Training gaps 