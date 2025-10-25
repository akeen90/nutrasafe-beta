# Fix Xcode Warnings - Manual Steps

## Issue 2: Remove Swift Files from Copy Bundle Resources

These Swift files shouldn't be in "Copy Bundle Resources" - they should only be compiled.

**In Xcode:**

1. Click on the **blue NutraSafeBeta** project icon in the left sidebar
2. Select the **"NutraSafe Beta"** target (orange app icon)
3. Click the **"Build Phases"** tab at the top
4. Expand **"Copy Bundle Resources"**
5. Find and **remove** these files (select and press Delete key):
   - `OnboardingManager.swift`
   - `OnboardingView.swift`
   - `OnboardingScreens.swift`
6. They should stay in "Compile Sources" phase (don't remove them from there!)

## Issue 3: Fix AccentColor

**In Xcode:**

1. In the left sidebar, navigate to: **Assets.xcassets**
2. Look for **"AccentColor"** in the list
3. If it exists but is empty:
   - Click on it
   - In the right panel (Attributes Inspector), set a color
   - OR: Right-click → Delete it (if you're not using a custom accent color)

## Issue 4: Fix AppIcon Unassigned Children

**In Xcode:**

1. In **Assets.xcassets**, click on **"AppIcon"**
2. You'll see many empty slots
3. **Either**:
   - Drag your app icon images into the correct slots (1024×1024 for the big one)
   - OR: If you don't need all sizes, this is just a warning (won't prevent submission)

For App Store submission, you MUST have at least:
- **1024×1024** icon (the big one at the bottom)

---

## Quick Fix Script (for bundle resources only)

I can't automate the Xcode UI changes, but here's verification:

```bash
# Check what's in Copy Bundle Resources
grep -A 50 "PBXResourcesBuildPhase" NutraSafeBeta.xcodeproj/project.pbxproj | grep "\.swift"
```

If you see Swift files there, remove them via Xcode UI as described above.
