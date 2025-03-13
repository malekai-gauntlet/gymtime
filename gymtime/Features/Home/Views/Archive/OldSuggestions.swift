// 📄 Archive of suggestions functionality removed from WorkoutTableView.swift

import SwiftUI

/*
 This file contains code that was removed from WorkoutTableView.swift
 to keep the original file cleaner while preserving the original functionality
 for potential future use.
 
 The code includes:
 1. Suggested workouts section
 2. Blank workout entry functionality
 3. Related count calculations
 */

// MARK: - Suggested Workouts Section

/*
// Code from lines ~150-198
ForEach(viewModel.suggestedWorkouts) { suggestion in
    WorkoutRow(
        workout: suggestion,
        scrollProxy: proxy,
        exerciseWidth: exerciseWidth,
        weightWidth: weightWidth,
        setsWidth: setsWidth,
        repsWidth: repsWidth,
        notesWidth: notesWidth,
        viewModel: viewModel,
        isAnyFieldEditing: $isAnyFieldEditing
    )
    .background(Color.gymtimeBackground)
    .opacity(0.4)
    .overlay(
        Button(action: {
            
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.addSuggestionToWorkouts(suggestion)
            }
        }) {
            ZStack {
                // Invisible larger tap area
                Color.clear
                    .frame(width: 60, height: 60)
                    .onTapGesture {
                        print("🎯 Tap area hit for \(suggestion.exercise)")
                    }
                
                // Visual checkmark remains the same size
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gymtimeAccent)
                    .font(.system(size: 24))
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            print("🔲 Suggestion button appeared: \(suggestion.exercise)")
        }
        .padding(.trailing, 24),
        alignment: .trailing
    )
    .transition(.opacity.combined(with: .move(edge: .bottom)))
    .onAppear {
        print("📍 Suggestion row appeared: \(suggestion.exercise)")
    }
}
*/

// MARK: - Blank Workout Entry

/*
// Code from lines ~201-220
if let blankWorkout = viewModel.blankWorkoutEntry {
    WorkoutRow(
        workout: blankWorkout,
        scrollProxy: proxy,
        exerciseWidth: exerciseWidth,
        weightWidth: weightWidth,
        setsWidth: setsWidth,
        repsWidth: repsWidth,
        notesWidth: notesWidth,
        viewModel: viewModel,
        isAnyFieldEditing: $isAnyFieldEditing,
        isBlankEntry: true
    )
    .background(Color.gymtimeBackground)
    .opacity(0.4)
    .transition(.opacity.combined(with: .move(edge: .bottom)))
}
*/

// MARK: - Count Calculations for BottomFadeModifier

/*
// Code from line ~227 (modifiers for item count)
.modifier(BottomFadeModifier(itemCount: workouts.count + (viewModel.blankWorkoutEntry != nil ? 1 : 0) + viewModel.suggestedWorkouts.count))
*/

// MARK: - Empty State Check

/*
// Code from line ~103 (additional empty state check)
if workouts.isEmpty && viewModel.suggestedWorkouts.isEmpty {
    // ...empty state UI...
}
*/ 