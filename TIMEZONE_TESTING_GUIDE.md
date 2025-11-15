# Timezone Fixes - Testing Guide

## Overview
This guide provides step-by-step instructions to verify that all timezone-related bugs have been fixed in the NutraSafe app.

---

## Pre-Testing Checklist

1. **Build the App**: Ensure the app compiles successfully with all new changes
2. **Clear App Data**: Reset the app to test with fresh data
3. **Note Current Timezone**: Document your device's timezone before testing
4. **Enable Debug Logging**: Check that `#if DEBUG` logs are visible in console

---

## Test Suite

### Test 1: Diary Entry Date Grouping (Local Timezone)

**Purpose**: Verify diary entries appear on correct calendar day regardless of timezone

**Steps**:
1. Set device time to 23:55 (11:55 PM)
2. Add a food entry to dinner
3. Wait until after midnight (device shows 00:05 next day)
4. Check which day the entry appears on

**Expected Result**:
- Entry added at 23:55 should appear on the PREVIOUS day's diary
- Entry should NOT move to next day after midnight passes

**What This Tests**: `DiaryDataManager.keyForDate()` using local timezone

---

### Test 2: Use-By Date Calculations

**Purpose**: Verify use-by dates calculate days correctly in local timezone

**Steps**:
1. Add a food item with use-by date = tomorrow at noon
2. Check "days until expiry" value
3. Change device timezone by +3 hours
4. Recheck "days until expiry" value

**Expected Result**:
- Should always show "1 day" until expiry
- Days count should NOT change when timezone changes
- "Expires Tomorrow" badge should remain consistent

**What This Tests**: `UseByInventoryItem.daysUntilExpiry` using `DateHelper.daysUntilExpiry()`

---

### Test 3: Use-By Notifications (Local Time)

**Purpose**: Verify notifications fire at correct local time

**Steps**:
1. Add food item with use-by date = 2 days from now
2. Enable use-by notifications in settings
3. Check notification center for pending notifications
4. Verify notification times are shown in local timezone

**Expected Result**:
- Should see 2 notifications scheduled:
  - "Expiring Tomorrow" at 9:00 AM local time (1 day before expiry)
  - "Expiring Today" at 9:00 AM local time (on expiry day)
- Times should be in device's current timezone

**What This Tests**: `UseByNotificationManager` using `DateHelper.timeIntervalUntil()`

**Verification Command** (iOS simulator):
```bash
xcrun simctl push <device-id> com.yourapp.nutrasafe notification.json
```

---

### Test 4: Firebase Date Queries (UTC vs Local)

**Purpose**: Verify Firebase queries return correct entries for local calendar day

**Steps**:
1. Set device timezone to UTC-8 (Pacific Time)
2. Add entry at 01:00 AM local time (this is 09:00 UTC)
3. View diary for "today"
4. Change device timezone to UTC+1 (Central European Time)
5. View diary for "today" again

**Expected Result**:
- Entry should appear in today's diary in BOTH timezones
- Entry should NOT disappear when timezone changes
- Firebase query boundaries should account for local day

**What This Tests**: `FirebaseManager.getFoodEntries()` using `DateHelper.firebaseDayBoundaries()`

---

### Test 5: DST Transition Handling

**Purpose**: Verify date calculations work correctly across DST boundaries

**Steps**:
1. Set device date to 1 day before DST spring forward (e.g., March 9, 2025 in US)
2. Add entry at 23:00 (11 PM)
3. Set device date to after DST (March 10, 2025 at 03:00)
4. Check which day entry appears on
5. Verify "days between" calculations

**Expected Result**:
- Entry should remain on March 9
- "Yesterday" label should work correctly
- Day count calculations should be accurate (1 day = 1 calendar day, not 23 hours)

**What This Tests**: `DateHelper.addDays()`, `DateHelper.daysBetween()` using Calendar API

**Note**: DST dates vary by region:
- US: Second Sunday of March (spring forward), First Sunday of November (fall back)
- EU: Last Sunday of March (spring forward), Last Sunday of October (fall back)
- AU: First Sunday of October (spring forward), First Sunday of April (fall back)

---

### Test 6: Reaction Log Time Windows

**Purpose**: Verify reaction analysis uses correct time range in local timezone

**Steps**:
1. Add 3 food entries over 3 consecutive days
2. Add a reaction log on day 4 with 3-day lookback
3. Check "trigger analysis" includes all 3 days of entries
4. Verify time calculations in hours are correct

**Expected Result**:
- All 3 days of entries should be included in analysis
- "Hours before reaction" should be accurate in local time
- No entries should be missed due to timezone conversion

**What This Tests**: `ReactionLogManager.analyzeReactionTriggers()` using `DateHelper.addDays()`

---

### Test 7: Midnight Boundary Cases

**Purpose**: Verify operations at exactly midnight work correctly

**Steps**:
1. Set device time to 23:59:00 (11:59 PM)
2. Add a food entry
3. Wait 2 minutes (until 00:01 next day)
4. Check which day entry appears on
5. Try to move entry to "today" (should be next day now)

**Expected Result**:
- Entry added at 23:59 appears on previous day
- "Today" in move dialog should refer to new day after midnight
- No entries should be lost or duplicated at midnight boundary

**What This Tests**: `DateHelper.startOfDay()`, `DateHelper.endOfDay()`, DST-safe midnight calculation

---

### Test 8: Date Comparison Consistency

**Purpose**: Verify same-day comparisons work across all features

**Steps**:
1. Add entries at different times on same day (06:00, 12:00, 23:00)
2. Check diary view groups all under same day
3. Use "is today" filter in various views
4. Verify "yesterday" badge works correctly

**Expected Result**:
- All entries on same calendar day group together
- "Today" badge shows for current day only
- "Yesterday" works correctly even across timezone changes

**What This Tests**: `DateHelper.isSameDay()`, `isToday()`, `isYesterday()`

---

### Test 9: Nutrient Tracking Date Grouping

**Purpose**: Verify nutrient data aggregates by correct local day

**Steps**:
1. Add foods with micronutrients on 3 different days
2. View nutrient timeline/heatmap
3. Check that each day's data is correctly grouped
4. Verify date labels match calendar days

**Expected Result**:
- Nutrient data should group by local calendar day
- Timeline should show correct dates for each data point
- Heatmap cells should align with calendar days

**What This Tests**: `NutrientTrackingManager.formatDateId()`, `MicronutrientTrackingManager.formatDate()`

---

### Test 10: Cache Key Consistency

**Purpose**: Verify cache keys use consistent timezone

**Steps**:
1. Add entry and verify it loads (cache miss)
2. Reload same day view (should hit cache)
3. Change timezone
4. Reload view again
5. Check cache behavior

**Expected Result**:
- Cache should hit when viewing same local day
- Cache keys should be based on local date
- Timezone change may cause cache miss (expected) but data should still load

**What This Tests**: `DiaryCacheActor.formatDateKey()`, `WeekDataCache.formatWeekKey()`

---

## Edge Cases to Test

### Edge Case 1: International Date Line
- Set timezone to UTC+12 (Fiji) or UTC-12 (Baker Island)
- Verify diary entries work correctly
- Test moving entries across dates

### Edge Case 2: Half-Hour Timezones
- Set timezone to UTC+5:30 (India) or UTC+9:30 (Australia)
- Verify all date calculations work correctly
- Test notification scheduling

### Edge Case 3: Year Boundary
- Set date to December 31, 23:59
- Add entry
- Wait until January 1
- Verify entry appears on correct year/day

### Edge Case 4: Leap Year
- Set date to February 29, 2024 (leap year)
- Add entries
- Verify date calculations don't break
- Test "add 365 days" type operations

---

## Automated Testing (Future)

### Unit Tests to Add

```swift
import XCTest
@testable import NutraSafe

class DateHelperTests: XCTestCase {
    func testSameDayComparison() {
        let date1 = Date(timeIntervalSince1970: 1700000000) // Morning
        let date2 = Date(timeIntervalSince1970: 1700050000) // Evening same day
        XCTAssertTrue(DateHelper.isSameDay(date1, date2))
    }

    func testDaysBetween() {
        let today = Date()
        let tomorrow = DateHelper.addDays(1, to: today)!
        XCTAssertEqual(DateHelper.daysBetween(from: today, to: tomorrow), 1)
    }

    func testStartOfDay() {
        let date = Date(timeIntervalSince1970: 1700012345) // Random time
        let startOfDay = DateHelper.startOfDay(for: date)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testDSTTransition() {
        // Test spring forward: 2025-03-09 02:00 -> 03:00 (US)
        let beforeDST = DateComponents(year: 2025, month: 3, day: 9, hour: 1)
        let afterDST = DateComponents(year: 2025, month: 3, day: 10, hour: 1)

        guard let date1 = Calendar.current.date(from: beforeDST),
              let date2 = Calendar.current.date(from: afterDST) else {
            XCTFail("Failed to create DST test dates")
            return
        }

        // Should be exactly 1 day apart, not 23 hours
        XCTAssertEqual(DateHelper.daysBetween(from: date1, to: date2), 1)
    }
}
```

---

## Debugging Tools

### Enable Verbose Date Logging

Add this to key date operations:

```swift
#if DEBUG
DateHelper.debugDate(someDate, label: "Entry Date")
// Output:
// 🕐 Entry Date:
//    Local: 2025-03-15 23:30:00 (America/Los_Angeles)
//    UTC:   2025-03-16 06:30:00
//    Timestamp: 1710570600.0
#endif
```

### Check Firebase Query Boundaries

```swift
#if DEBUG
let (start, end) = DateHelper.firebaseDayBoundaries(for: date)
print("📅 Firebase query: \(start) to \(end)")
print("   Start local: \(DateHelper.localDateKey(for: start))")
print("   End local: \(DateHelper.localDateKey(for: end))")
#endif
```

### Verify Notification Times

```swift
#if DEBUG
if let interval = DateHelper.timeIntervalUntil(date: date, hour: 9, minute: 0) {
    let triggerDate = Date(timeIntervalSinceNow: interval)
    print("🔔 Notification will fire at: \(triggerDate)")
    print("   Local time: \(DateHelper.localDateFormatter(format: "yyyy-MM-dd HH:mm:ss").string(from: triggerDate))")
}
#endif
```

---

## Success Criteria

All tests should pass with:
- ✅ No diary entries on wrong dates
- ✅ Use-by calculations always correct
- ✅ Notifications at correct local times
- ✅ Firebase queries return expected data
- ✅ DST transitions handled smoothly
- ✅ Timezone changes don't break features
- ✅ Midnight boundaries work correctly
- ✅ Cache hits/misses as expected

---

## Rollback Plan

If issues are found:
1. Document the specific test case that failed
2. Check `TIMEZONE_FIXES_SUMMARY.md` for affected files
3. Revert specific file if needed: `git checkout HEAD~1 -- path/to/file.swift`
4. File an issue with test case details

---

## Post-Testing

After all tests pass:
1. Update release notes with "Fixed timezone handling bugs"
2. Enable analytics for date-related operations
3. Monitor for any reports of date/time issues
4. Consider adding automated UI tests for critical flows

---

**Note**: Always test on both physical device and simulator. Physical device is preferred for notification testing as it has real system clock and timezone settings.
