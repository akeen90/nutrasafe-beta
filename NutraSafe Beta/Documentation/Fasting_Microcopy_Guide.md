# Fasting Feature Microcopy Guide

## Overview
This document contains all the user-facing text (microcopy) for the fasting feature system. All copy is designed to be supportive, non-shaming, and encouraging.

## Core Principles
- **Supportive tone**: Never shame or judge
- **Encouraging language**: Focus on progress, not perfection
- **Clear guidance**: Simple, actionable information
- **Personal empowerment**: User is in control

---

## Main Screens

### Fasting Main View

#### Idle State (No Active Session)
**Header**: "Ready to Begin"
**Subtitle**: "Start your fasting journey with a personalized plan"
**Primary Button**: "Start Fasting"
**Secondary Button**: "Learn About Fasting"

**Active Plan Card**:
- Title: "Your Active Plan"
- Next Scheduled: "Next: [Date]"
- Duration: "[X] hours"
- Days: "[Count] days/week"

#### Active Session State
**Progress Ring Center**:
- Elapsed: "[HH:MM]"
- Target: "of [X]h"

**Status Messages**:
- Progress < 100%: "[Next milestone] in [X]h"
- Progress >= 100%: "Goal achieved! 🎉"

**Action Buttons**:
- "End Fast"
- "Edit Times"
- "Skip Today"

**Motivational Messages** (rotate randomly):
- "You're doing great — stay steady."
- "Hydration helps the journey."
- "Progress compounds."
- "Consistency > perfection."
- "Breathe and stay present."
- "Your body is adapting beautifully."
- "Every hour counts."
- "Trust the process."

---

### Fasting Plan Creation

#### Plan Details Section
**Header**: "Plan Details"
**Name Field**: "Plan Name"
**Duration Picker**: "Duration"
**Custom Duration**: "Custom Hours: [X]"

#### Days of Week Section
**Header**: "Days of Week"
**Day Toggles**: "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"

#### Drink Philosophy Section
**Header**: "Allowed Drinks Philosophy"
**Philosophy Options**:

**Strict Clean** (Blue theme)
- Title: "Strict Clean"
- Subtitle: "scientific"
- Description: "Water, plain tea, black coffee, electrolytes only"
- Allowed items:
  - "Water (still or sparkling)"
  - "Plain black coffee"
  - "Plain tea (black, green, herbal)"
  - "Electrolyte supplements"
  - "Salt water"

**Practical** (Green theme)
- Title: "Practical"
- Subtitle: "lifestyle"
- Description: "Sugar-free drinks allowed"
- Allowed items:
  - "All strict items"
  - "Sugar-free drinks"
  - "Diet sodas (occasionally)"
  - "Zero-calorie flavored water"
  - "Black coffee with zero-cal sweeteners"

**Lenient** (Pink theme)
- Title: "Lenient"
- Subtitle: "beginner friendly"
- Description: "<20–30 kcal tolerance"
- Allowed items:
  - "All practical items"
  - "Coffee with splash of milk (<30 cal)"
  - "Tea with honey (<30 cal)"
  - "Bone broth (<30 cal)"
  - "Small amounts of creamer"

#### Reminders Section
**Header**: "Reminders"
**Toggle**: "Enable Reminders"
**Reminder Timing**: "Remind me before end"
**Options**: "5 minutes", "15 minutes", "30 minutes", "1 hour", "2 hours"

**Create Button**: "Create Plan"

---

### Fasting Plan Management

#### Header
**Title**: "Fasting Plans"
**Navigation**: "Plans" / "Insights"

#### Active Plan Card
**Title**: "Active Plan"
**Plan Name**: "[Plan Name]"
**Duration**: "[Duration Display]"
**Days**: "Days: [Mon, Tue, ...]"
**Drinks**: "[Philosophy Name]"
**Reminders**: "Reminds [X] min before end"
**Next Scheduled**: "Next: [Date]"

#### All Plans Section
**Header**: "All Plans"
**Empty State**: "No Fasting Plans"
**Empty State Subtitle**: "Create your first fasting plan to get started with structured fasting."

**Plan Row**:
- Plan name
- Duration and days count
- Drink philosophy
- Active indicator: "✓" (green)

**Swipe Actions**:
- Activate: "Activate" (green)
- Delete: "Delete" (red)

---

### Fasting Insights

#### Header
**Title**: "Fasting Insights"
**Subtitle**: "Progress compounds. Consistency > perfection."
**Time Range Picker**: "7 Days" / "30 Days" / "All Time"

#### Key Metrics Section
**Header**: "Key Metrics"

**Metric Cards**:
1. **Total Fasts**
   - Value: "[Count]"
   - Subtitle: "[Time Range]"
   - Icon: "checkmark.circle"

2. **Success Rate**
   - Value: "[XX]%"
   - Subtitle: "Average"
   - Icon: "percent"

3. **Avg Duration**
   - Value: "[X]h [Y]m"
   - Subtitle: "vs Goal"
   - Icon: "clock.fill"

4. **Longest Fast**
   - Value: "[Duration]"
   - Subtitle: "Record"
   - Icon: "trophy.fill"

#### Progress Chart Section
**Header**: "Progress Over Time"
**Empty State**: "Not Enough Data"
**Empty State Subtitle**: "Complete a few more fasting sessions to see your progress chart."

#### Phase Distribution Section
**Header**: "Phase Distribution"
**Empty State**: "No Phase Data"
**Empty State Subtitle**: "Complete some fasting sessions to see which phases you reach most often."

#### Consistency Analysis Section
**Header**: "Consistency Analysis"

**Consistency Metrics**:
1. **Most Consistent Day**
   - Value: "[Day Name]"
   - Icon: "calendar.circle.fill"

2. **Weekly Average**
   - Value: "[X.X]"
   - Subtitle: "fasts per week"
   - Icon: "chart.bar.fill"

3. **Current Streak**
   - Value: "[Count]"
   - Subtitle: "completed sessions"
   - Icon: "flame.fill"

**Motivational Text**: "Consistency builds habits. Every fast counts toward your goals."

#### Recent Sessions Section
**Header**: "Recent Sessions"
**View All Button**: "View All"

---

### End Session Options

**Title**: "How did your fast go?"

**End Options**:
1. **Completed Goal**
   - Title: "Completed Goal"
   - Description: "I reached my target duration"
   - Icon: "checkmark.circle.fill"

2. **Ended Early**
   - Title: "Ended Early"
   - Description: "I stopped before my goal"
   - Icon: "clock.badge.exclamationmark"

3. **Over Goal**
   - Title: "Over Goal"
   - Description: "I exceeded my target time"
   - Icon: "arrow.up.circle.fill"

**Cancel Button**: "Cancel"

---

## Education Screens

### Fasting Education

#### Header
**Title**: "Understanding Fasting"
**Subtitle**: "Choose an approach that fits your lifestyle and goals"

#### Fasting Timeline Section
**Header**: "Fasting Timeline"
**Intro Text**: "Your body goes through different phases during fasting. These are approximate timelines:"

**Phase Descriptions**:
- **0-4h**: "Post-meal processing"
- **4-8h**: "Fuel switching"
- **8-12h**: "Fat mobilization"
- **12-16h**: "Mild ketosis"
- **16-20h**: "Autophagy potential"
- **20h+**: "Deep adaptive fasting"

**Disclaimer**: "Remember: Everyone's body is different. These timelines are general guidelines, not strict rules."

#### Helpful Tips Section
**Header**: "Helpful Tips"

**Tips**:
1. **Stay Hydrated**
   - "Drink plenty of water throughout your fast. Hydration helps reduce hunger and supports your body's natural processes."

2. **Start Slow**
   - "If you're new to fasting, begin with shorter durations (12-14 hours) and gradually increase as your body adapts."

3. **Listen to Your Body**
   - "Pay attention to how you feel. If you experience severe discomfort, dizziness, or other concerning symptoms, break your fast."

4. **Be Consistent**
   - "Regular fasting is more beneficial than occasional long fasts. Aim for consistency rather than perfection."

5. **Break Gently**
   - "When ending your fast, start with small, easily digestible foods. Avoid heavy meals immediately after fasting."

#### Getting Started Section
**Header**: "Ready to Start?"

**Intro Text**: "Remember: Fasting is a personal journey. What works for others may not work for you."

**Guidance**: "Start with a plan that feels manageable, and adjust as you learn what your body needs."

**Key Message**: "Progress compounds. Consistency > perfection."

**Motivational Messages**:
- "Every hour counts"
- "Trust the process"
- "Breathe and stay present"
- "Your body is adapting beautifully"

---

## Widget Copy

### Small Status Widget

#### Idle State
**Icon**: "moon.stars.fill"
**Status**: "Ready"
**Action**: "Tap to start"
**Motivation**: "Tap to begin your next fast"

#### Active State
**Header**: "Fasting"
**Elapsed Time**: "[HH:MM]"
**Phase**: "[Current Phase]"
**Motivation**: "[Random supportive message]"

#### Near End State
**Icon**: "flag.checkered"
**Status**: "Almost there! 💪"
**Elapsed**: "[HH:MM]"
**Motivation**: "Stay focused — you're almost there!"

#### Over Goal State
**Icon**: "trophy.fill"
**Status**: "Goal achieved! 🎉"
**Elapsed**: "[HH:MM]"
**Motivation**: "Amazing work! Goal exceeded."

#### Skipped State
**Icon**: "forward.fill"
**Status**: "Skipped Today"
**Message**: "Reset tomorrow"
**Motivation**: "Tomorrow is a new day."

### Medium Progress Widget

#### Idle State
**Header**: "Fasting Progress"
**Status**: "Ready to Start"
**Action**: "Tap to begin your next fast"
**Motivation**: "Your next fast awaits"

#### Active State
**Header**: "Fasting Active"
**Elapsed**: "[HH:MM] elapsed"
**Remaining**: "[HH:MM] remaining"
**Next Milestone**: "[Phase] in [X]h"
**Motivation**: "[Random supportive message]"

#### Quick Action Widget
**Header**: "Fasting Actions"
**Actions**: "End" / "Edit" / "Skip"
**Status Bar**: "[Elapsed time] • [Current phase]"

---

## Error Messages

### Validation Errors
**Empty Plan Name**: "Please enter a plan name"
**No Days Selected**: "Please select at least one day"
**Invalid Duration**: "Duration must be between 1 and 168 hours"
**Invalid Time Range**: "End time must be after start time"

### Session Errors
**Active Session Exists**: "A fasting session is already active"
**No Active Session**: "No active fasting session found"
**Cannot Delete Active Plan**: "Cannot delete an active fasting plan"

### Network Errors
**Offline Mode**: "Working offline. Changes will sync when connected."
**Sync Failed**: "Unable to sync. Please check your connection."

---

## Success Messages

### Plan Creation
**Success**: "Plan created successfully!"
**Activation**: "Plan activated and ready to use"

### Session Management
**Session Started**: "Your fast has begun. Stay focused!"
**Session Ended**: "Great job! Your fast is complete."
**Session Skipped**: "No problem. Tomorrow is a new day."
**Times Updated**: "Session times updated successfully"

### General
**Data Saved**: "Your changes have been saved"
**Settings Updated**: "Settings updated successfully"

---

## Onboarding Copy

### First Use Education Overlay
**Title**: "Welcome to Fasting!"
**Subtitle**: "Let's set up your preferred approach to drinks during fasting."
**Button**: "Get Started"

### Feature Introduction
**Title**: "Personalized Fasting Plans"
**Description**: "Create custom fasting schedules that fit your lifestyle"

**Title**: "Track Your Progress"
**Description**: "Monitor your fasting journey with detailed insights"

**Title**: "Supportive Guidance"
**Description**: "Get encouraging reminders and helpful tips"

---

## Accessibility Labels

### Main View
**Start Button**: "Start fasting session"
**End Button**: "End current fasting session"
**Progress Ring**: "Fasting progress: [X] percent complete"
**Phase Timeline**: "Current fasting phase: [Phase name]"

### Plan Creation
**Duration Picker**: "Select fasting duration"
**Day Toggle**: "Toggle [Day name] for fasting"
**Philosophy Card**: "Select [Philosophy name] drink philosophy"

### Widgets
**Small Widget**: "Current fasting status: [Status]"
**Progress Widget**: "Fasting progress ring showing [X] percent complete"
**Action Widget**: "Fasting quick actions: End, Edit, Skip"

---

## Tone Guidelines

### Do Use
- "You're doing great"
- "Stay focused"
- "Progress compounds"
- "Consistency > perfection"
- "Every hour counts"
- "Trust the process"
- "Your body is adapting"
- "Tomorrow is a new day"

### Don't Use
- "You failed"
- "You broke your fast"
- "You cheated"
- "You should have..."
- "You didn't reach..."
- "You messed up"
- "You were weak"
- "You gave up"

### Alternative Phrases
Instead of "Failed": "Ended early" / "Not completed"
Instead of "Broke fast": "Ended session" / "Stopped fasting"
Instead of "Cheated": "Chose a different approach"
Instead of "Didn't reach goal": "Progress made toward goal"

---

## Localization Notes

### Key Terms
- "Fasting" - Core feature name
- "Session" - Individual fasting period
- "Plan" - Scheduled fasting routine
- "Phase" - Biological fasting stage
- "Goal" - Target duration
- "Progress" - Completion percentage

### Cultural Considerations
- Avoid religious fasting terminology unless specifically requested
- Use inclusive language ("your body" vs "the body")
- Focus on health and wellness rather than weight loss
- Emphasize personal choice and flexibility

### Date/Time Formatting
- Use device locale settings
- 12/24 hour format based on user preference
- Relative time for recent events ("2 hours ago")
- Absolute time for specific events ("Started at 3:30 PM")