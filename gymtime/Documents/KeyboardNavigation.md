# Keyboard Navigation Implementation Guide

## Overview
This document outlines the steps required to implement Previous/Next arrow navigation in the keyboard toolbar for the workout entry fields. This enhancement will allow users to easily navigate between fields without dismissing the keyboard.

## Implementation Steps

### 1. Create a Focus Management System
- Create a way to track which fields can be focused
- Establish a clear navigation order between fields
- Store references to which field is currently active

### 2. Update EditableCell to Participate in Navigation
- Modify EditableCell to accept and report its position in the navigation order
- Add ability to programmatically trigger focus on a field
- Include callbacks for when navigation buttons are pressed

### 3. Enhance the WorkoutRow Component
- Track which cells within a row can be navigated between
- Provide a mechanism to navigate to the next/previous row when reaching the end/beginning of fields in current row

### 4. Implement Custom Keyboard Toolbar
- Add Previous/Next arrow buttons to the keyboard toolbar
- Style the buttons to match your app's design
- Add appropriate accessibility labels

### 5. Create Navigation Logic
- Implement the logic to determine the next/previous field
- Handle edge cases (first field/last field)
- Ensure navigation works across different workout rows

### 6. Add Visual Feedback
- Highlight the currently focused field
- Possibly scroll to ensure the focused field is visible
- Add subtle animations for smooth transitions between fields

### 7. Test Edge Cases
- Test navigation at the beginning/end of the list
- Verify behavior when a row is added or deleted
- Ensure it works with different keyboard types (numeric vs text)

### 8. Optimize Performance
- Ensure navigation is smooth and responsive
- Minimize any layout shifts during navigation
- Optimize scrolling behavior when navigating between distant fields

### 9. Add Accessibility Support
- Ensure VoiceOver announces the navigation properly
- Add appropriate accessibility traits to navigation buttons
- Test with various accessibility settings

### 10. Polish the User Experience
- Add haptic feedback when navigating (optional)
- Fine-tune animations and transitions
- Ensure keyboard dismissal still works properly with Done button

## Technical Considerations

### Navigation Order
The navigation order should follow a natural pattern:
1. Navigate horizontally across fields within a row (Exercise → Weight → Sets → Reps → Notes)
2. When reaching the end of a row, move to the first field of the next row
3. When going backward from the first field, move to the last field of the previous row

### Focus State
- Use SwiftUI's `@FocusState` to manage focus
- Create a custom struct to represent focusable fields
- Implement a state machine to handle focus transitions

### Implementation in EditableCell
The EditableCell will need to be modified to:
- Accept a binding to the current focus state
- Report its position in the navigation order
- Provide callbacks for next/previous actions

### Keyboard Toolbar Implementation
```swift
// Example toolbar structure (pseudo-code)
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Button(action: moveToPreviousField) {
            Image(systemName: "chevron.left")
        }
        .disabled(!hasPreviousField)
        
        Spacer()
        
        Button(action: moveToNextField) {
            Image(systemName: "chevron.right")
        }
        .disabled(!hasNextField)
        
        Spacer()
        
        Button("Done") {
            dismissKeyboard()
        }
    }
}
```

## Future Enhancements
- Consider adding tab key support for external keyboards
- Explore automatically advancing to the next field when specific conditions are met
- Add support for entering multiple values quickly with smart separators 