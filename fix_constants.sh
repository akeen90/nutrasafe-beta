#!/bin/bash

# Script to replace all constants in Swift files
echo "Starting constant replacement..."

# Find all Swift files in Views directory
VIEWS_DIR="/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views"

# Replace AtomicConstants
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/AtomicConstants\.standardSpacing/16/g' \
  -e 's/AtomicConstants\.smallSpacing/8/g' \
  -e 's/AtomicConstants\.wideSpacing/24/g' \
  -e 's/AtomicConstants\.largeSpacing/20/g' \
  -e 's/AtomicConstants\.extraLargeSpacing/32/g' \
  -e 's/AtomicConstants\.cornerRadius/12/g' \
  -e 's/AtomicConstants\.smallCornerRadius/8/g' \
  -e 's/AtomicConstants\.fullOpacity/1.0/g' \
  -e 's/AtomicConstants\.highOpacity/0.9/g' \
  -e 's/AtomicConstants\.lowOpacity/0.3/g' \
  -e 's/AtomicConstants\.veryLowOpacity/0.05/g' \
  -e 's/AtomicConstants\.percentageBase/100/g' \
  -e 's/AtomicConstants\.slowAnimationDuration/1.0/g' \
  -e 's/AtomicConstants\.standardHeight/100/g' \
  -e 's/AtomicConstants\.padding16/16/g' \
  -e 's/AtomicConstants\.padding12/12/g' \
  -e 's/AtomicConstants\.padding8/8/g' \
  -e 's/AtomicConstants\.padding6/6/g' \
  -e 's/AtomicConstants\.padding4/4/g' \
  -e 's/AtomicConstants\.padding2/2/g' \
  -e 's/AtomicConstants\.padding14/14/g' \
  -e 's/AtomicConstants\.padding32/32/g' \
  -e 's/AtomicConstants\.fontSizeLarge/24/g' \
  -e 's/AtomicConstants\.fontSizeMediumLarge/18/g' \
  -e 's/AtomicConstants\.fontSizeMedium/16/g' \
  -e 's/AtomicConstants\.fontSizeSmall/14/g' \
  -e 's/AtomicConstants\.fontSizeExtraSmall/10/g' \
  -e 's/AtomicConstants\.iconSizeLarge/60/g' \
  -e 's/AtomicConstants\.iconSizeMedium/24/g' \
  -e 's/AtomicConstants\.circleSize24/24/g' \
  -e 's/AtomicConstants\.labelWidth80/80/g' \
  -e 's/AtomicConstants\.unitWidth40/40/g' \
  -e 's/AtomicConstants\.minQuantityWidth80/80/g' \
  {} \;

# Replace ColorConstants
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/ColorConstants\.primaryBlue/.blue/g' \
  -e 's/ColorConstants\.primary/.blue/g' \
  -e 's/ColorConstants\.cardBackground/Color(.systemGray6)/g' \
  -e 's/ColorConstants\.errorRed/.red/g' \
  -e 's/ColorConstants\.dangerRed/.red/g' \
  -e 's/ColorConstants\.successGreen/.green/g' \
  -e 's/ColorConstants\.warningOrange/.orange/g' \
  -e 's/ColorConstants\.secondaryGray/.gray/g' \
  -e 's/ColorConstants\.separatorGray/.gray/g' \
  {} \;

# Replace StringConstants with literal strings
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/StringConstants\.clock/"clock"/g' \
  -e 's/StringConstants\.dropFill/"drop.fill"/g' \
  -e 's/StringConstants\.stopCircleFill/"stop.circle.fill"/g' \
  -e 's/StringConstants\.playCircleFill/"play.circle.fill"/g' \
  -e 's/StringConstants\.plusCircleFill/"plus.circle.fill"/g' \
  -e 's/StringConstants\.plus/"plus"/g' \
  -e 's/StringConstants\.settings/"Settings"/g' \
  -e 's/StringConstants\.dailyWaterCountKey/"dailyWaterCount"/g' \
  -e 's/StringConstants\.workoutInProgress/"Workout in Progress"/g' \
  -e 's/StringConstants\.exercisesLabel/"exercises"/g' \
  -e 's/StringConstants\.continueWorkout/"Continue Workout"/g' \
  -e 's/StringConstants\.quickStart/"Quick Start"/g' \
  -e 's/StringConstants\.startEmptyWorkout/"Start Empty Workout"/g' \
  -e 's/StringConstants\.createCustomWorkout/"Create a custom workout"/g' \
  -e 's/StringConstants\.yourWorkouts/"Your Workouts"/g' \
  -e 's/StringConstants\.workoutTemplates/"Workout Templates"/g' \
  -e 's/StringConstants\.starterTemplates/"Starter Templates"/g' \
  -e 's/StringConstants\.userWorkoutTemplatesKey/"userWorkoutTemplates"/g' \
  -e 's/StringConstants\.strengthBeginner/"Strength (Beginner)"/g' \
  -e 's/StringConstants\.strengthIntermediate/"Strength (Intermediate)"/g' \
  -e 's/StringConstants\.strengthAdvanced/"Strength (Advanced)"/g' \
  -e 's/StringConstants\.cardio/"Cardio"/g' \
  -e 's/StringConstants\.strengthFunctional/"Strength (Functional)"/g' \
  -e 's/StringConstants\.strengthBodyweight/"Strength (Bodyweight)"/g' \
  -e 's/StringConstants\.durationText(minutes: template\.estimatedDuration)/"\(template.estimatedDuration) min"/g' \
  {} \;

# Replace custom view modifiers
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/\.standardHorizontalPadding()/.padding(.horizontal, 16)/g' \
  -e 's/\.standardCornerRadius()/.cornerRadius(12)/g' \
  {} \;

echo "Constant replacement complete!"
echo "Files processed:"
find "$VIEWS_DIR" -name "*.swift" -type f | wc -l