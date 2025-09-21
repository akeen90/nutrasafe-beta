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
1. ✅ **Search System**: Manual, barcode, AI scanner, search with intelligent barcode prioritization
2. ✅ **Allergen Detection**: Comprehensive allergy warning system with immediate ingredient display
3. ✅ **Nutrition Scoring**: A+ to F grading algorithm
4. ✅ **Ingredient Analysis**: Full ingredient breakdown with safety ratings
5. ✅ **Apple Health**: Real-time exercise calorie integration
6. ✅ **Pattern Analysis**: Non-medical food reaction tracking
7. ✅ **Micronutrient Tracking**: Daily value percentages
8. ✅ **Barcode Management**: External source barcode extraction and internal database prioritization
9. ✅ **AI Scanning**: Enhanced nutrition label processing with proper per-100g conversion
10. ✅ **Admin Dashboard**: Professional food verification system with detailed view modals
11. ✅ **Data Preservation**: Complete ingredient and photo preservation during verification process

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
- **iOS App**: ✅ Fully functional with HealthKit, latest Firebase iOS SDK v10.29.0
- **Firebase Functions**: ✅ All functions upgraded and deployed with Node.js 20 runtime
  - Firebase Functions: v5.1.1 (latest compatible)
  - Firebase Admin: v12.7.0 
  - All dependencies updated (Axios v1.11.0, TypeScript v5.9.2, CORS v2.8.5)
- **Web Dashboard**: ✅ Deployed with enhanced admin interface and professional food detail views
- **Security**: ✅ All credentials properly managed
- **Features**: ✅ Comprehensive nutrition tracking system with advanced barcode management
- **Runtime**: ✅ Node.js 20 runtime ready for Firebase deployment
- **Data Flow**: ✅ Complete verification workflow with ingredient/photo preservation
- **Search Intelligence**: ✅ Internal database prioritization over external sources

## 🚀 Next Steps

### Immediate Priorities
1. **App Store Deployment**: Complete iOS app upload to TestFlight/App Store
2. **User Testing**: Beta testing with real users for feedback collection

### Future Enhancements
3. **UK Localization**: British spelling and legal compliance updates
4. **Enhanced Onboarding**: UK-specific user flow and dietary preferences
5. **Advanced Analytics**: User behavior insights and food trends
6. **Meal Planning**: Weekly meal suggestions based on nutrition goals
7. **Social Features**: Food sharing and community recommendations
8. **Offline Mode**: Core functionality without internet connection

### Technical Improvements
9. **Performance Optimization**: Faster image processing and search results
10. **Advanced AI**: Better ingredient recognition and nutritional analysis
11. **Integration Expansions**: More health apps and fitness trackers
12. **Export Features**: PDF reports and data export capabilities

## 📱 Testing
- Use iPhone 16 Pro simulator for iOS testing
- Firebase Functions available at: https://us-central1-nutrasafe-705c7.cloudfunctions.net/
- Web dashboard: https://nutrasafe-705c7.web.app

Remember: Security first, features second. Never compromise on API key safety.