# NutraSafe Development Guide

This is a comprehensive food safety and nutrition tracking app with Firebase backend.

## 🔒 SECURITY CRITICAL
- **NEVER commit API keys to git**
- All sensitive keys are in `.env` (git-ignored)
- Use environment variables for production deployment
- API keys are placeholders in committed code

## 🎨 Design Philosophy

NutraSafe follows a **premium, emotion-first design language** that emphasizes clarity, calm, and trust.

### Core Principles

1. **Emotional Resonance Over Clinical Precision**
   - Lead with empathy and understanding, not data dumps
   - Use warm, natural language: "Your body already knows. We're here to help you listen."
   - Design flows around user feelings: "safer", "lighter", "in control"

2. **User-Adaptive Color System**
   - Dynamic palettes that shift based on user intent (see [OnboardingTheme.swift](NutraSafe%20Beta/Views/Onboarding/Premium/OnboardingTheme.swift))
   - **Safer**: Deep teal, midnight blue, silver (trust, stability)
   - **Lighter**: Sunrise peach, soft coral, warm cream (energy, vitality)
   - **In Control**: Sage green, warm stone, grounded earth (balance, knowledge)
   - Background gradients animate smoothly between states

3. **Typography Hierarchy**
   - **Headlines**: Serif, 32-34pt bold, tight tracking (-0.5) — editorial, confident
   - **Subheadlines**: Serif, 24-28pt semibold — clear hierarchy
   - **Body**: Default, 17pt regular, generous line spacing (+6pt) — comfortable reading
   - **Captions**: 12-14pt, wide tracking (0.4-0.5) — subtle, refined
   - **Buttons**: Default, 17pt semibold, letter-spacing (0.3) — clear actions

4. **Interaction Design**
   - Gentle transitions (0.3-0.4s ease-in/out) between screens
   - Breathing animations and ripple effects for processing states
   - Auto-advance after selections (0.8s delay) — reduce friction
   - Tactile feedback: subtle scale (0.98) on press
   - Cards with soft shadows (5-15pt blur) and rounded corners (14-20pt)

5. **Content Strategy**
   - Progressive disclosure: reveal complexity gradually
   - Context before data: explain "why" before "what"
   - Personalized messaging based on user choices
   - Visual emphasis through spacing, not decoration
   - Icons as emotional cues (🍞🥛🥚) not just labels

6. **Information Architecture**
   - **Onboarding Flow**: Breath → Intent → Goals → Activity → Habits → Details → Sensitivities → Permissions → Completion
   - **Main Navigation**: Diary (meals + insights) → Progress (weight + diet) → Health (reactions + fasting) → Use By (reminders)
   - **Tab Design**: Icon + color-coded (orange, teal, pink, cyan) with descriptive subtabs
   - Tips and guidance on first visit to each section

7. **Accessibility & Clarity**
   - High contrast text on adaptive backgrounds
   - Icons paired with text labels
   - Clear affordances for interactive elements
   - Screen reader friendly descriptions
   - Generous touch targets (48-56pt height)

8. **Emotional Journey Mapping**
   - Start with breath and reflection
   - Build trust through understanding ("Listening...", "Processing...")
   - Offer choice, not prescription
   - Celebrate completion with encouragement
   - Maintain calm, confident tone throughout

### Design Reference Files
- [OnboardingTheme.swift](NutraSafe%20Beta/Views/Onboarding/Premium/OnboardingTheme.swift) — Color palettes, typography, user intents
- [PremiumOnboardingView.swift](NutraSafe%20Beta/Views/Onboarding/Premium/PremiumOnboardingView.swift) — Full onboarding flow
- [WelcomeScreenView.swift](NutraSafe%20Beta/Views/Onboarding/WelcomeScreenView.swift) — Post-onboarding navigation guide

### When Creating New Views
✅ **DO:**
- Use adaptive color schemes (`.adaptiveBackground`, `.secondarySystemBackground`)
- Follow the established typography scale
- Add generous padding (16-32pt horizontal, 12-24pt vertical)
- Use rounded corners (12-20pt) consistently
- Include loading/processing states with animations
- Design for both light and dark mode

❌ **DON'T:**
- Overcrowd screens with information
- Use harsh, clinical language
- Mix design patterns from different sections
- Skip empty states or error messages
- Hardcode colors (use theme system)
- Add features without considering emotional impact

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
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
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

## 🗑️ Dead Code to Remove

When you encounter old/duplicate code, add it here for future cleanup:

### Cleaned Up (January 2026)
- ✅ `FastingMainViewLegacy` and 30+ supporting views (~3,870 lines) - removed from FastingMainView.swift
- ✅ `MacroManagementView`, `BMRCalculatorSheet`, and supporting views (~1,350 lines) - removed from SettingsView.swift
- ✅ `AdditiveTrackerSectionLegacy` (~1,000 lines) - replaced with emotion-first redesign (AdditiveInsightsRedesigned.swift)

### Redesigned for Brand Consistency (January 2026)
- ✅ **Additive Insights** - Completely redesigned to match onboarding aesthetic
  - User-adaptive color palettes from onboarding intent (safer/lighter/control)
  - Single contextual insight instead of 4 overlapping sections
  - Removed verbose "why track additives" repetition
  - Clean serif typography matching premium feel
  - Gentle animations and breathing room
  - Changed from clinical data dump to emotional clarity

### Guidelines
- Always use redesigned views (`*Redesigned`) over old versions
- When creating new views, prefix old ones for removal here
- Before builds, check this list and remove dead code when safe
- **Match the onboarding philosophy**: Warm language, minimal repetition, trust-building