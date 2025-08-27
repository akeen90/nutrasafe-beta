# NutraSafe Development Guide

This is a comprehensive food safety and nutrition tracking app with Firebase backend.

## 🔒 SECURITY CRITICAL
- **NEVER commit API keys to git**
- All sensitive keys are in `.env` (git-ignored)
- Use environment variables for production deployment
- API keys are placeholders in committed code

## 🏗️ Architecture

### iOS App (SwiftUI)
- **Main**: NutraSafeBetaApp.swift
- **UI**: ContentView.swift with comprehensive nutrition tracking
- **Data**: DataModels.swift with ingredient analysis system
- **Firebase**: FirebaseManager.swift for all backend operations
- **Health**: HealthKitManager.swift for Apple Health integration

### Firebase Backend
- **Functions**: `firebase/functions/src/index.ts`
- **Database**: Firestore with user-based collections
- **Hosting**: Public web dashboards

### Key Features Implemented
1. ✅ **Search System**: Manual, barcode, AI scanner, search
2. ✅ **Allergen Detection**: Comprehensive allergy warning system  
3. ✅ **Nutrition Scoring**: A+ to F grading algorithm
4. ✅ **Ingredient Analysis**: Full ingredient breakdown with safety ratings
5. ✅ **Apple Health**: Real-time exercise calorie integration
6. ✅ **Pattern Analysis**: Non-medical food reaction tracking
7. ✅ **Micronutrient Tracking**: Daily value percentages

## 🛠️ Development Commands

### iOS Development
```bash
# Build iOS app
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta"
xcodebuild -project NutraSafeBeta.xcodeproj -scheme "NutraSafe Beta" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build
```

### Firebase Development
```bash
# Build and deploy functions
cd firebase/functions
npm run build
firebase deploy --only functions

# Deploy hosting
firebase deploy --only hosting

# Test locally
firebase serve
```

### Security Checklist
- [ ] API keys in `.env` only
- [ ] `.gitignore` properly configured  
- [ ] No hardcoded credentials in code
- [ ] Firebase rules properly secured
- [ ] Regular billing monitoring

## 📊 Current Status
- **iOS App**: ✅ Fully functional with HealthKit
- **Firebase**: ✅ All functions deployed and secure
- **Security**: ✅ All credentials properly managed
- **Features**: ✅ Comprehensive nutrition tracking system

## 🚀 Next Steps
1. UK localization (spelling and legal compliance)
2. UK-based onboarding flow
3. Enhanced reporting features
4. Advanced meal planning

## 📱 Testing
- Use iPhone 16 Pro simulator for iOS testing
- Firebase Functions available at: https://us-central1-nutrasafe-705c7.cloudfunctions.net/
- Web dashboard: https://nutrasafe-705c7.web.app

Remember: Security first, features second. Never compromise on API key safety.