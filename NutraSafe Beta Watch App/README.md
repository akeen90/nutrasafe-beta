# NutraSafe Apple Watch App

## Overview
The NutraSafe Apple Watch app provides quick access to nutrition tracking and health insights directly from your wrist. It syncs seamlessly with the iPhone app to give you real-time access to your food diary and nutrition scores.

## Features

### 📊 Today View
- **Daily Nutrition Summary**: View your nutrition grade, total calories, and macro breakdown
- **Recent Foods**: See the last foods you've logged with their grades
- **Real-time Sync**: Pull to refresh for latest data from your iPhone

### ➕ Quick Add
- **Quick Food Buttons**: Pre-configured healthy foods you can add with one tap
- **iPhone Integration**: Open search or barcode scanner on your iPhone
- **Haptic Feedback**: Confirmation when foods are successfully added

### ⭐ Nutrition Score
- **Daily Grade**: Large, color-coded nutrition grade (A+ to F)
- **Grade Breakdown**: Visual breakdown of food grades logged today
- **Progress Tracking**: Daily progress toward calorie and protein goals

### ❤️ Health Stats
- **Activity Rings**: Steps and exercise calories with progress indicators
- **Heart Rate**: Current and resting heart rate from Apple Watch sensors
- **Calorie Balance**: Net calories (consumed vs burned)
- **Weekly Trends**: Average grades and activity over the week

## Technical Architecture

### Core Components
- **WatchDataManager**: Manages local data state and calculations
- **WatchConnectivityManager**: Handles communication with iPhone app
- **WatchHealthKitManager**: Integrates with Apple Health for activity data

### Data Models
- **WatchFoodEntry**: Simplified food entry for Watch display
- **WatchNutritionSummary**: Daily nutrition aggregation
- **WatchHealthData**: Activity and health metrics
- **WatchQuickFood**: Pre-configured quick-add foods

### Health Integration
- HealthKit integration for steps, exercise calories, and heart rate
- Real-time heart rate monitoring during active use
- Privacy-first approach with explicit user permissions

## Setup Instructions

### 1. Add Watch Target to Xcode
1. Open your NutraSafeBeta.xcodeproj
2. Add a new WatchOS App target
3. Set the bundle identifier to match your iPhone app + `.watchkitapp`
4. Add the Watch app files to the new target

### 2. Configure App Groups (Recommended)
```swift
// Add to both iPhone and Watch targets
let appGroupID = "group.com.yourdomain.nutrasafe"
```

### 3. Update iPhone App for Connectivity
Add WatchConnectivity support to your iPhone app:
```swift
import WatchConnectivity

class iPhoneConnectivityManager: NSObject, WCSessionDelegate {
    // Handle Watch app requests
    // Send nutrition data updates
    // Process quick food additions
}
```

### 4. Health Permissions
The Watch app requests permissions for:
- Heart Rate (real-time monitoring)
- Resting Heart Rate (baseline metrics)
- Steps (daily activity)
- Active Energy Burned (exercise calories)

## Communication Protocol

### iPhone → Watch Messages
- `todayData`: Complete nutrition summary and recent foods
- `quickFoods`: Updated list of quick-add options
- `foodAdded`: Notification when food is successfully logged

### Watch → iPhone Messages
- `request: "todayData"`: Request current nutrition data
- `request: "quickAdd", foodId: "..."`: Add a quick food to diary
- `action: "openSearch"`: Open iPhone app to search screen
- `action: "openScanner"`: Open iPhone app to barcode scanner

## User Experience

### Navigation
- Tab-based interface optimized for small screen
- Scrollable content with haptic feedback
- Color-coded nutrition grades throughout

### Performance
- Local data caching for offline viewing
- Efficient data sync to preserve battery
- Lightweight UI optimized for Watch hardware

### Accessibility
- Large, readable text and buttons
- High contrast color scheme
- VoiceOver support for all interactive elements

## Future Enhancements

### Planned Features
- Voice input for food logging ("Add apple to my diary")
- Complication support for Watch faces
- Independent food database for offline use
- Custom quick food configuration
- Workout integration for automatic calorie adjustments

### Technical Improvements
- Core Data sync between iPhone and Watch
- Background app refresh for nutrition updates
- Advanced health metric correlations
- Smart notifications for meal reminders

## Development Notes

### Build Requirements
- Xcode 15.0+
- iOS 17.0+ (iPhone app)
- watchOS 10.0+
- Swift 5.9+

### Dependencies
- SwiftUI (UI framework)
- WatchConnectivity (iPhone-Watch communication)
- HealthKit (health and activity data)

### Testing
Test on actual Apple Watch hardware for:
- Performance optimization
- Battery usage
- Haptic feedback
- Health data accuracy

The Watch app is designed to complement your iPhone nutrition tracking with quick, glanceable information and simple interaction patterns perfect for wrist-based computing.