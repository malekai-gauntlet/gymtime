# MyFitnessPal-Style Onboarding Implementation

## Overview
Simple implementation of first-time user tooltips that match MyFitnessPal's style, with a dimmed background and arrows pointing to UI elements.

## Implementation Steps

### Basic Setup
- [ ] Create `hasSeenTooltip` AppStorage variables in HomeView
- [ ] Create simple `TooltipOverlay` view modifier

### Tooltip UI
- [ ] Create basic tooltip bubble with:
  - [ ] White background
  - [ ] Rounded corners
  - [ ] Arrow pointing to target
  - [ ] Title text
  - [ ] Description text

### Home Screen Implementation
- [ ] Add tooltip for record button:
  - [ ] "Record your workout with voice"
  - [ ] Arrow pointing to record button
  - [ ] Show on first app open

- [ ] Add tooltip for plus button:
  - [ ] "Add exercises manually"
  - [ ] Arrow pointing to plus button
  - [ ] Show after record button tooltip is dismissed

### Styling
- [ ] Add semi-transparent black overlay (opacity ~0.5)
- [ ] Match MyFitnessPal font styles
- [ ] Add smooth fade in/out animations

### User Interaction
- [ ] Implement tap-to-dismiss anywhere on screen
- [ ] Save tooltip state when dismissed
- [ ] Ensure tooltips don't reappear after being seen

## Testing
- [ ] Test on first app open
- [ ] Verify tooltips appear in correct sequence
- [ ] Check tooltip positioning on different screen sizes
- [ ] Verify tooltips don't reappear after being dismissed

## Future Enhancements (Optional)
- [ ] Add tooltips for other tabs
- [ ] Add way to reset/view tooltips again
- [ ] Add progress indicator for multiple tooltips 