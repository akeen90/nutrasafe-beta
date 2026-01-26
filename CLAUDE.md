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

## 🌐 Website Development Standards

### CRITICAL: Every New Page MUST Include

When creating or updating website pages in `/firebase/public/`, **ALWAYS** include:

1. **Cookie Consent Script**
   ```html
   <script src="/cookie-consent.js" defer></script>
   ```
   - Add before closing `</head>` tag
   - Required for GDPR compliance and analytics opt-in

2. **Analytics Tracking**
   - Google Analytics is loaded via cookie-consent.js after user consent
   - No additional tags needed if cookie-consent.js is included

3. **Consistent Navigation**
   - **Header navigation** must link to: Features, How It Works, Blog, Resources, Download
   - **Footer** must include all site sections for discoverability
   - New pages MUST be added to sitemap.xml
   - Link to new pages from relevant existing pages (internal linking)

### Page Checklist
Before deploying any new page, verify:
- [ ] Cookie consent script included
- [ ] Page added to sitemap.xml
- [ ] Internal links from related pages
- [ ] Header/footer navigation present
- [ ] Mobile responsive
- [ ] Meta tags (title, description, og:image)
- [ ] Canonical URL set

**Why this matters:** Consistent navigation improves SEO (internal linking), user experience (easy discovery), and compliance (cookie consent).

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
12. ✅ **Favorites System**: Stable sheet presentation with .id() prevents dismissal when unfavoriting foods

## 🐛 Debugging Protocol

### ⚠️ CRITICAL: Always Verify Active Components First
**Before making ANY changes or checking functionality**, you MUST:

1. **Find what's actually being used** - This codebase has many duplicate/legacy views
   ```bash
   # Find where a view is instantiated (not just defined)
   grep -r "ViewName(" "NutraSafe Beta/Views/" --include="*.swift"
   ```

2. **Trace the full call chain** - Don't assume the obvious file is the active one
   - Start from ContentView.swift or the entry point
   - Follow each navigation/presentation to the actual view being displayed
   - Verify with grep that the component you're editing is actually instantiated

3. **Common naming patterns for duplicates:**
   - `*Legacy`, `*Old`, `*Redesigned`, `*Clean`, `*Modern`, `*New`, `*V2`
   - The file you think is active might be dead code
   - The "redesigned" version might not be wired up yet

**Example verification:**
```bash
# Wrong: Assuming NotificationSettingsView is used
# Right: Verify it's actually called
grep -r "NotificationSettingsView" "NutraSafe Beta/" --include="*.swift" | grep -v "struct NotificationSettingsView"
```

### When UI Changes Don't Appear
If you've made changes but they're not showing in the app, **DO NOT assume it's a build cache issue**. Follow this protocol:

1. **Trace the execution path** - Find which component is ACTUALLY being rendered

2. **Check for duplicate/unused components** - Multiple versions of the same view often exist
   - Look for `*Legacy`, `*Old`, `*Redesigned`, `Clean*`, `Modern*` variants
   - The newest code might be in an unused component

3. **Verify the call chain** - From ContentView → Tab → Section → Row
   - ContentView.swift: Which tab view is called?
   - Tab view: Which main view is called?
   - Main view: Which row/cell component is used in ForEach?

4. **Common gotchas in this codebase:**
   - `UseByTabView` calls `UseByExpiryView` which uses `CleanUseByRow` (not `ModernExpiryRow`)
   - Multiple "redesigned" views exist but may not be wired up
   - After reverts, old component names might be restored

### What to Say to Claude
If Claude is going in circles:
- "Stop guessing. Trace the actual code path being executed."
- "Find which component is ACTUALLY being rendered, not which exists in the file."
- "Grep for where this view is instantiated/called."
- "The code exists but isn't showing - find what's being called instead."

## 🚫 ANTI-LOOP PATTERNS (CRITICAL!)

**NEVER write code with infinite loops.** Always add safety limits, break conditions, and progress tracking.

### Known Loop Issues (FIXED - Don't repeat!)

#### 1. React Component Re-render Loops
**Problem:** Component recreates functions on every render, triggering React Fast Refresh infinitely.

❌ **BAD:**
```typescript
// DON'T: Function recreated every render
const MyComponent = () => {
  loadDataRef.current = async () => {
    // ... async work
  };

  const loadData = useCallback(() => loadDataRef.current?.(), []);

  useEffect(() => loadData(), []); // Calls new function each render!
}
```

✅ **GOOD:**
```typescript
// DO: Wrap in useCallback with dependencies
const MyComponent = () => {
  const loadData = useCallback(async () => {
    // ... async work
  }, [dependency1, dependency2]); // Stable reference

  useEffect(() => loadData(), []); // Calls once
}
```

**Files affected:** `firebase/public/admin-v2/src/App.tsx`, `MasterDatabaseBuilderPage.tsx`

#### 2. Pagination Loops (Backend API)
**Problem:** `hasMore: true` returned even when no data left, causing infinite pagination.

❌ **BAD:**
```typescript
while (hasMore) {
  const result = await fetchPage(offset);
  hasMore = result.hasMore; // If backend always says true = infinite loop!
  offset += pageSize;
}
```

✅ **GOOD:**
```typescript
const MAX_ITERATIONS = 2000; // Safety limit
let iterations = 0;

while (hasMore && iterations < MAX_ITERATIONS) {
  iterations++;
  const result = await fetchPage(offset);

  // Safety: Stop if no products returned
  if (result.products.length === 0) {
    hasMore = false;
    break;
  }

  // Safety: Stop if less than full page (last page)
  if (result.products.length < pageSize) {
    hasMore = false;
  }

  hasMore = result.hasMore;
  offset += pageSize;
}

if (iterations >= MAX_ITERATIONS) {
  console.warn('Hit safety limit');
}
```

**Files affected:** `firebase/public/admin-v2/src/components/MasterDatabaseBuilderPage.tsx`

#### 3. O(n²) Algorithm Performance (Not a Loop, But Acts Like One)
**Problem:** Comparing every product with every other product = 2.6 billion comparisons for 72k items.

❌ **BAD:**
```typescript
// O(n²) - Would take 16+ hours for 72k items!
for (let i = 0; i < products.length; i++) {
  for (let j = i + 1; j < products.length; j++) {
    if (similar(products[i], products[j])) {
      // ...
    }
  }
}
```

✅ **GOOD:**
```typescript
// O(n) - Use hash-based bucketing
const barcodeIndex = new Map<string, Product[]>();
const nameIndex = new Map<string, Product[]>();

// Build indices (O(n))
for (const product of products) {
  const barcode = product.barcode;
  if (!barcodeIndex.has(barcode)) barcodeIndex.set(barcode, []);
  barcodeIndex.get(barcode).push(product);

  const nameKey = product.name.substring(0, 15);
  if (!nameIndex.has(nameKey)) nameIndex.set(nameKey, []);
  nameIndex.get(nameKey).push(product);
}

// Find duplicates within buckets (only compare similar items)
for (const [barcode, items] of barcodeIndex) {
  if (items.length > 1) {
    // Only compare items with same barcode (small group)
    // ...
  }
}
```

**Files affected:** `firebase/public/admin-v2/src/components/MasterDatabaseBuilderPage.tsx`

#### 4. Vite Dev Server HMR Loops
**Problem:** Build process modifies watched files, triggering reload, which re-runs build, etc.

❌ **BAD:**
```json
// package.json - build modifies index.html which dev watches
{
  "dev": "vite",
  "build": "vite build && cp dist/index.html ."
}
```

✅ **GOOD:**
```json
// Copy source HTML before dev starts, ignore built files
{
  "dev": "cp index.src.html index.html && vite",
  "build": "cp index.src.html index.html && vite build && cp dist/index.html ."
}
```

```typescript
// vite.config.ts - Ignore built files
export default defineConfig({
  server: {
    watch: {
      ignored: [
        '**/dist/**',
        '**/assets/**',
        '**/index.html' // Ignore production index.html
      ]
    }
  }
})
```

**Files affected:** `firebase/public/admin-v2/package.json`, `vite.config.ts`

### Loop Prevention Checklist

Before writing ANY loop, pagination, or async iteration:

- [ ] **Add MAX_ITERATIONS** safety limit (1000-2000 for large datasets)
- [ ] **Check for empty results** - Stop if API returns 0 items
- [ ] **Check for partial page** - Stop if results < pageSize (last page)
- [ ] **Add progress logging** every 100-1000 iterations to show it's working
- [ ] **Add elapsed time tracking** to estimate completion
- [ ] **Use `await new Promise(resolve => setTimeout(resolve, 0))`** every N iterations to allow UI updates
- [ ] **Consider algorithm complexity** - Is there an O(n) or O(n log n) alternative to O(n²)?
- [ ] **Wrap functions in useCallback** with proper dependencies (React)
- [ ] **Initialize state with functions** `useState(() => initialValue)` not `useState(initialValue)` (React)
- [ ] **Ignore build artifacts** in file watchers (Vite, Webpack, etc.)

### When You See "Loading..." for Too Long

If something is loading for >30 seconds:

1. **Open browser console** (F12) - Look for errors or infinite requests
2. **Check Network tab** - Is the same request firing repeatedly?
3. **Check for while/for loops** - Do they have break conditions?
4. **Check algorithm complexity** - Is it O(n²) or worse?
5. **Add console.log with timestamps** - Confirm progress or detect stuck state

**If you create a loop issue:** Document it here immediately so future Claude doesn't repeat it!

## 🛠️ Development Commands

### iOS Development
```bash
# Build iOS app (always try OS=26.0 first, fallback to 18.6 if not available)
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
xcodebuild -project NutraSafeBeta.xcodeproj -scheme "NutraSafe Beta" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build
```

**Note:** Always try iOS 26.0 simulator first. If that fails, fall back to OS=18.6.

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

### Admin Dashboard Deployment (CRITICAL)

When deploying the admin v2 dashboard (`/firebase/public/admin-v2/`):

1. **Build the dashboard**
   ```bash
   cd firebase/public/admin-v2
   npm run build
   ```

2. **Deploy to Firebase**
   ```bash
   cd firebase
   firebase deploy --only hosting
   ```

3. **ALWAYS VERIFY THE DEPLOYMENT ACTUALLY WORKS** (REQUIRED - NOT OPTIONAL)

   ⚠️ **CRITICAL**: Checking if HTML loads is NOT enough. You MUST verify the app actually initializes.

   **INCORRECT** ❌:
   - "The page shows a loading spinner" = NOT VERIFIED
   - "The title is present" = NOT VERIFIED
   - "No errors in HTML" = NOT VERIFIED

   **CORRECT** ✅:
   - **Tell the user to open the URL in their browser** and check:
     1. Does the loading spinner disappear after 5-10 seconds?
     2. Does the main dashboard UI appear (sidebar, header, grid)?
     3. Are there any red error messages in the browser console (F12)?

   - **YOU CANNOT VERIFY THIS WITH WebFetch** - WebFetch only sees initial HTML, not JavaScript initialization
   - **YOU MUST ASK THE USER** to confirm the dashboard loads in their browser

   Example conversation:
   ```
   Assistant: "Deployment complete. Please open https://nutrasafe-705c7.web.app/admin-v2/
               in your browser and confirm:
               1. Loading spinner disappears
               2. Dashboard appears (sidebar + main grid)
               3. No console errors (F12)

               Let me know if you see any issues."
   ```

   **If you say "deployment complete" without user confirmation, YOU FAILED**.

### Admin Dashboard Dev Server (CRITICAL)

When starting the dev server for admin v2 (`/firebase/public/admin-v2/`):

**⚠️ STEP 0: ALWAYS CHECK THIS FIRST** (MOST COMMON ISSUE)

**If the user reports "spinning" or "stuck loading", CHECK THIS IMMEDIATELY:**

```bash
# Check if index.html has production build files (WRONG for dev)
grep "index-.*\.js" /Users/aaronkeen/Documents/My\ Apps/NutraSafe/firebase/public/admin-v2/index.html
```

**If you see production filenames** (like `index-_wno3f55.js`), the HTML is wrong:

```bash
# Fix: Reset to dev HTML
cd /Users/aaronkeen/Documents/My\ Apps/NutraSafe/firebase/public/admin-v2
cp index.src.html index.html

# Kill and restart dev server
pkill -9 -f vite 2>/dev/null || true
npm run dev &

# Tell user to HARD REFRESH (Cmd+Shift+R)
```

**Why this happens:** After running `npm run build`, the production `index.html` gets copied to the root, overwriting the dev version. The `npm run dev` script copies `index.src.html` to `index.html`, but if the build was run after dev started, the HTML gets out of sync.

**ALWAYS check this FIRST before investigating other issues.**

---

1. **Start the dev server**
   ```bash
   cd /Users/aaronkeen/Documents/My\ Apps/NutraSafe/firebase/public/admin-v2
   npm run dev
   ```

2. **ALWAYS VERIFY THE DEV SERVER ACTUALLY WORKS** (REQUIRED - NOT OPTIONAL)

   ⚠️ **CRITICAL**: curl checking HTML is NOT enough. You MUST verify the app actually works.

   **Step 1: Check server started**
   ```bash
   # Wait for startup
   sleep 5

   # Verify HTML is being served
   curl -s http://localhost:5173/admin-v2/ | head -60 | grep -E "NutraSafe|root"
   ```

   **Step 2: ACTUALLY VERIFY IT WORKS**
   - **YOU CANNOT VERIFY WITH CURL ALONE** - curl only sees HTML, not if React loads
   - **YOU MUST ASK THE USER** to open the browser and confirm:
     1. Does the loading spinner disappear after 5-10 seconds?
     2. Does the dashboard UI appear (sidebar, header, grid)?
     3. Are there console errors in browser DevTools (F12)?

   Example conversation:
   ```
   Assistant: "Dev server started on http://localhost:5173/admin-v2/

               Please open this URL in your browser and confirm:
               1. Loading spinner disappears
               2. Dashboard appears with sidebar and grid
               3. No red errors in console (press F12)

               Let me know if it's working or stuck."
   ```

   **INCORRECT** ❌:
   - "Dev server is running" = NOT VERIFIED
   - "curl returns HTML" = NOT VERIFIED
   - "Should work fine" = NOT VERIFIED

   **CORRECT** ✅:
   - Get explicit user confirmation the dashboard UI loaded

3. **Common Issues**
   - **Port in use**: Vite tries another port automatically (5174, 5175) - this is normal
   - **Stuck loading spinner**: JavaScript error during initialization - check browser console
   - **Build errors**: TypeScript errors prevent compilation - check terminal
   - **Old processes**: Kill with `pkill -f "vite.*admin-v2"` and restart

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
  - NO animations - instant expand/collapse with Transaction.disablesAnimations
  - Changed from clinical data dump to emotional clarity

- ✅ **Additive Detail Views** - Redesigned expandable information architecture (AdditiveRedesignedViews.swift)
  - **"What I need to know"** section: 3-4 concise health-focused bullet points (always visible)
    - Key claims: child warnings, PKU warnings, allergens, regulatory verdicts
    - Color-coded by risk level (red/orange/yellow/green bullets)
    - Health-first language: "May affect children's activity", "Some studies suggest limiting intake"
  - **"Scientific Background"** section: Collapsible long-form explanation (starts closed)
    - Uses existing `overview` and `effectsSummary` from database
    - Custom Button-based expansion (no DisclosureGroup animations)
    - Includes typical uses where available
  - **Edge-to-edge layout**: Cards extend full width (negative -24pt padding to compensate parent)
  - **No animations**: Transaction with disablesAnimations = true for instant show/hide
  - **Consistent padding**: 24pt horizontal throughout (matches screen edge spacing)
  - **Personal sensitivity warnings**: Highlighted when additive affects user's stated sensitivities

- ✅ **Use By Add Screen** - Premium emotion-first redesign (UseByAddRedesigned.swift)
  - Emotional headline: "Track what you have" with warm subtitle
  - Three method cards with gradient icons and clear hierarchy
  - User-adaptive color palettes matching onboarding intent
  - Generous spacing (20-24pt padding) and breathing room
  - Serif headlines (32pt), clear body text (15-17pt)
  - Soft shadows and rounded corners (18pt radius)
  - Contextual empty states with encouraging messaging
  - Search flow with smooth transitions and gentle loading states
  - Trust-building language: "Never waste food. Know what needs eating soon."

- ✅ **Use By Quick Add Card** - Premium inline card redesign (UseByQuickAddRedesigned.swift)
  - Emotional headline: "Track what you have" (20pt serif)
  - Warm tagline: "Never waste. Always know." (subtle, empowering)
  - Two-button layout: "Scan" (outlined) and "Add Item" (gradient primary)
  - User-adaptive accent colors from onboarding intent
  - Gradient backgrounds with soft shadows (12pt blur)
  - Rounded corners (20pt card, 14pt buttons)
  - Tactile scale feedback (0.97) on button press
  - Gentle border glow matching user's intent palette
  - 52pt button height for comfortable touch targets

- ✅ **Use By Food Detail Screen** - Premium item add screen redesign (UseByFoodDetailRedesigned.swift)
  - Calm, focused layout with adaptive backgrounds
  - Large serif headline (24pt) for food name
  - User-adaptive color palettes matching onboarding intent
  - Elegant expiry date selector with calendar and quick modes
  - Smart freshness messaging: "Plenty of time", "Use this week", "Use today"
  - Color-coded freshness indicators (accent, green, yellow, orange)
  - Clean notes field with subtle placeholder styling
  - Photo upload with dashed border invitation (140pt height)
  - Fixed bottom button: "Add Item" with gradient (56pt height)
  - Generous spacing (18-20pt padding) and rounded corners (12-16pt)
  - Tactile button feedback throughout
  - Trust-building language over clinical terminology

### Guidelines
- Always use redesigned views (`*Redesigned`) over old versions
- When creating new views, prefix old ones for removal here
- Before builds, check this list and remove dead code when safe
- **Match the onboarding philosophy**: Warm language, minimal repetition, trust-building