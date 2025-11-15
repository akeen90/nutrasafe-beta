# Timezone Handling Fixes - NutraSafe App

## Summary of Changes

This document summarizes all timezone-related fixes applied to ensure consistent date/time handling throughout the NutraSafe app.

---

## Problem Statement

The app had multiple timezone-related bugs:
- **Mixing local time with UTC**: Some code used `Date()` (local) while Firebase stored UTC timestamps
- **Inconsistent date comparisons**: Raw `Date` comparisons instead of calendar-based "same day" checks
- **Midnight boundary issues**: Incorrect use of date components without accounting for DST
- **Use-by dates showing wrong day**: Dates compared without timezone context
- **Diary entries on wrong date**: Entries grouped by UTC day instead of local day

---

## Solution: Centralized DateHelper Utility

### New File Created: `/NutraSafe Beta/Utils/DateHelper.swift`

A comprehensive timezone-safe date utility that provides:

1. **Local Timezone Operations** (for user-facing features):
   - Date comparisons: `isSameDay()`, `isToday()`, `isYesterday()`, `isTomorrow()`
   - Start/end of day: `startOfDay()`, `endOfDay()`
   - Date arithmetic: `addDays()`, `daysBetween()`
   - Date formatting: `localDateKey()`, `localDateFormatter()`

2. **UTC Operations** (for server communication):
   - UTC formatting: `utcDateKey()`, `utcDateFormatter()`

3. **Firebase Integration**:
   - Day boundaries: `firebaseDayBoundaries()` - converts local day to UTC range

4. **Notification Scheduling**:
   - Time calculations: `timeIntervalUntil()`, `notificationDateComponents()`

5. **Convenience Extensions**:
   - `Date.startOfDay`, `Date.endOfDay`, `Date.isToday`, etc.

---

## Files Modified

### 1. Core Data Management

#### `/NutraSafe Beta/Models/CoreModels.swift`
- **UseByInventoryItem.daysUntilExpiry**: Now uses `DateHelper.daysUntilExpiry()` for correct local timezone comparison
- **DiaryDataManager.keyForDate()**: Uses `DateHelper.localDateKey()` to ensure diary entries group by user's local day
- **DailyBreakdown formatting**: Uses `DateHelper.localDateFormatter()` for display strings

**Impact**: Fixes diary entries appearing on wrong date, use-by dates showing incorrect days

---

#### `/NutraSafe Beta/FirebaseManager.swift`
- **invalidateFoodEntriesCache()**: Uses `DateHelper.startOfDay()` and `DateHelper.localDateKey()`
- **getFoodEntries()**: Uses `DateHelper.firebaseDayBoundaries()` to query correct local day from UTC timestamps
- **getFoodEntriesForPeriod()**: Uses `DateHelper.addDays()` and `DateHelper.startOfDay/endOfDay()` for period ranges
- **deleteOldFoodEntries()**: Uses `DateHelper.startOfDay()` for consistent midnight calculation

**Impact**: Fixes diary entries not loading correctly across timezones, prevents midnight boundary bugs

---

#### `/Models/DiaryDataManager+MoveAcrossDates.swift`
- **moveFoodItemAcrossDates()**: Uses `DateHelper.isSameDay()` instead of `Calendar.isDate(_:inSameDayAs:)`

**Impact**: Ensures moving food items across dates works correctly in all timezones

---

### 2. Notification System

#### `/NutraSafe Beta/UseByNotificationManager.swift`
- **scheduleNotifications()**:
  - Uses `DateHelper.addDays()` to calculate notification dates
  - Uses `DateHelper.daysBetween()` to compare dates (not timestamps)
- **scheduleSingleNotification()**:
  - Uses `DateHelper.timeIntervalUntil()` to calculate notification trigger time
  - Removed manual Calendar date component construction

**Impact**: Fixes notifications firing at wrong times, especially across DST transitions

---

### 3. Reaction Log Analysis

#### `/NutraSafe Beta/Managers/ReactionLogManager.swift`
- **analyzeReactionTriggers()**: Uses `DateHelper.addDays()` to calculate time range in local timezone
- Added documentation noting timestamp comparisons are safe for filtering

**Impact**: Ensures reaction analysis uses correct time window in user's timezone

---

### 4. Tracking Managers

#### `/NutraSafe Beta/NutrientTrackingManager.swift`
- **formatDateId()**: Uses `DateHelper.localDateKey()` instead of custom DateFormatter

#### `/NutraSafe Beta/MicronutrientTrackingManager.swift`
- **formatDate()**: Uses `DateHelper.localDateKey()` instead of custom DateFormatter

#### `/NutraSafe Beta/Models/NutrientTrackingModels.swift`
- **DailyNutrientData.dateId**: Uses `DateHelper.localDateKey()`

**Impact**: Ensures nutrient tracking data is grouped by local calendar day

---

### 5. Cache Managers

#### `/NutraSafe Beta/Models/DiaryCacheActor.swift`
- **formatDateKey()**: Uses `DateHelper.localDateKey()`

#### `/NutraSafe Beta/Models/WeekDataCache.swift`
- **formatWeekKey()**: Uses `DateHelper.localDateFormatter()` for week-based keys

**Impact**: Cache keys now consistent with local timezone, preventing cache misses

---

## Key Principles Established

### 1. **Local Timezone for User Features**
Use `DateHelper` local methods for:
- Diary entries grouping
- Use-by date calculations
- Notification scheduling
- UI display
- Date comparisons ("same day", "is today", etc.)

### 2. **UTC for Server Communication**
Use `DateHelper` UTC methods when:
- Storing timestamps to Firebase (Firebase handles this automatically)
- Querying date ranges from Firebase (use `firebaseDayBoundaries()`)

### 3. **Always Use Calendar for Date Math**
Never use raw timestamp arithmetic for day calculations:
- ❌ `date.addingTimeInterval(24 * 3600)` - WRONG (doesn't account for DST)
- ✅ `DateHelper.addDays(1, to: date)` - CORRECT (uses Calendar)

### 4. **Compare Dates, Not Timestamps**
For "same day" checks:
- ❌ `date1 == date2` - WRONG (compares exact timestamps)
- ✅ `DateHelper.isSameDay(date1, date2)` - CORRECT (compares calendar days)

---

## Testing Recommendations

### Critical Test Cases:

1. **DST Transitions**:
   - Add diary entry at 23:00 on day before DST change
   - Verify it appears on correct day after DST change
   - Test notification scheduling across DST boundaries

2. **Timezone Changes**:
   - Log food in one timezone
   - Change device timezone
   - Verify entries still appear on correct calendar day

3. **Midnight Boundaries**:
   - Add entry at 23:59:59 local time
   - Verify it groups with correct day (not next day)
   - Test use-by dates expiring at midnight

4. **International Users**:
   - Test with timezones: UTC-12, UTC-0, UTC+12
   - Verify diary grouping works correctly
   - Test reaction analysis time windows

5. **Use-By Notifications**:
   - Set expiry for tomorrow
   - Verify "expiring tomorrow" notification fires at 9 AM local time
   - Test across DST transition dates

---

## Migration Notes

### Backward Compatibility
All changes are backward compatible:
- Existing Firebase data continues to work (timestamps are timezone-agnostic)
- Local cache keys use same format (`yyyy-MM-dd` in local timezone)
- No data migration required

### Performance Impact
Minimal impact:
- `DateHelper` methods are lightweight wrappers around `Calendar.current`
- Date formatters are created on-demand (could be cached in future if needed)
- Firebase queries unchanged (still using indexed timestamp fields)

---

## Future Improvements

1. **Cache DateFormatters**: Create reusable formatters to avoid repeated initialization
2. **Timezone Display**: Show user's timezone in debug views for troubleshooting
3. **Server Timezone Info**: Store user's timezone in Firebase for analytics
4. **DST Awareness**: Add UI indicators for DST transition days
5. **Date Range Validation**: Add helpers to validate date ranges don't cross DST boundaries unexpectedly

---

## Documentation

All `DateHelper` methods include:
- Clear parameter documentation
- Return value descriptions
- Timezone context (local vs UTC)
- Usage examples in comments

**Developers should always**:
- Use `DateHelper` instead of raw `Calendar.current` or `DateFormatter()`
- Document which timezone context each `Date` variable represents
- Never use timestamp arithmetic for day calculations
- Test date-related features across timezone boundaries

---

## Summary Statistics

- **Files Modified**: 11 core files
- **New Utility**: 1 comprehensive DateHelper utility (300+ lines)
- **Methods Standardized**: 15+ date formatting/comparison methods
- **Bug Classes Fixed**: 5 (date grouping, comparisons, notifications, boundaries, caching)
- **Test Coverage Needed**: DST, timezone changes, midnight boundaries, international users

---

**Result**: Timezone handling is now consistent, predictable, and maintainable throughout the NutraSafe app.
