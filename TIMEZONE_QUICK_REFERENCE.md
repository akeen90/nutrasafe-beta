# Timezone Handling - Quick Reference Card

## When to Use What

### ✅ Use DateHelper for Local Timezone Operations

**Diary Entry Grouping**
```swift
// ❌ DON'T
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"
let key = formatter.string(from: date)

// ✅ DO
let key = DateHelper.localDateKey(for: date)
```

**Same Day Comparison**
```swift
// ❌ DON'T
let sameDay = Calendar.current.isDate(date1, inSameDayAs: date2)

// ✅ DO
let sameDay = DateHelper.isSameDay(date1, date2)
```

**Start/End of Day**
```swift
// ❌ DON'T
let startOfDay = Calendar.current.startOfDay(for: date)

// ✅ DO
let startOfDay = DateHelper.startOfDay(for: date)
// or use extension
let startOfDay = date.startOfDay
```

**Add/Subtract Days**
```swift
// ❌ DON'T - Breaks during DST!
let tomorrow = date.addingTimeInterval(24 * 3600)

// ✅ DO
let tomorrow = DateHelper.addDays(1, to: date)
```

**Days Between Dates**
```swift
// ❌ DON'T
let days = Int(date2.timeIntervalSince(date1) / 86400)

// ✅ DO
let days = DateHelper.daysBetween(from: date1, to: date2)
```

---

### 🔥 Firebase Date Queries

**Query by Local Day**
```swift
// ✅ CORRECT - Get all entries for a local calendar day
let (start, end) = DateHelper.firebaseDayBoundaries(for: date)
let query = collection
    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
    .whereField("date", isLessThan: Timestamp(date: end))
```

**Query by Period**
```swift
// ✅ CORRECT - Get last N days of data
let endDate = DateHelper.endOfDay(for: Date())
guard let startDate = DateHelper.addDays(-days, to: Date()) else { return [] }
let queryStart = DateHelper.startOfDay(for: startDate)

let query = collection
    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: queryStart))
    .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
```

---

### 🔔 Notification Scheduling

**Schedule at Specific Time**
```swift
// ✅ CORRECT
guard let interval = DateHelper.timeIntervalUntil(date: targetDate, hour: 9, minute: 0) else {
    print("Date is in the past")
    return
}

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: interval,
    repeats: false
)
```

**Check if Date is in Future**
```swift
// ✅ CORRECT
let daysFromNow = DateHelper.daysBetween(from: Date(), to: targetDate)
if daysFromNow >= 0 {
    // Schedule notification
}
```

---

### 📅 Display Formatting

**Local Date String**
```swift
// ❌ DON'T
let formatter = DateFormatter()
formatter.dateFormat = "MMM d, yyyy"
let display = formatter.string(from: date)

// ✅ DO
let formatter = DateHelper.localDateFormatter(format: "MMM d, yyyy")
let display = formatter.string(from: date)
```

**Check if Today/Yesterday/Tomorrow**
```swift
// ✅ DO
if date.isToday {
    return "Today"
} else if date.isYesterday {
    return "Yesterday"
} else if date.isTomorrow {
    return "Tomorrow"
}
```

---

### 🗄️ Cache Keys

**Date-Based Cache Key**
```swift
// ✅ CORRECT - Use local date for grouping
let cacheKey = "\(userId)_\(DateHelper.localDateKey(for: date))"
```

**Week-Based Cache Key**
```swift
// ✅ CORRECT
let formatter = DateHelper.localDateFormatter(format: "yyyy-'W'ww")
let weekKey = formatter.string(from: weekStart)
```

---

## Common Patterns

### Pattern 1: Filtering Data by Date Range

```swift
func getItemsForDateRange(from: Date, to: Date) -> [Item] {
    let fromStart = DateHelper.startOfDay(for: from)
    let toEnd = DateHelper.endOfDay(for: to)

    return allItems.filter { item in
        item.date >= fromStart && item.date <= toEnd
    }
}
```

### Pattern 2: Grouping Items by Day

```swift
func groupItemsByDay(_ items: [Item]) -> [String: [Item]] {
    var grouped: [String: [Item]] = [:]

    for item in items {
        let key = DateHelper.localDateKey(for: item.date)
        grouped[key, default: []].append(item)
    }

    return grouped
}
```

### Pattern 3: Calculate Expiry Status

```swift
func expiryStatus(for expiryDate: Date) -> ExpiryStatus {
    let days = DateHelper.daysUntilExpiry(expiryDate: expiryDate)

    switch days {
    case ...(-1): return .expired
    case 0: return .expiringToday
    case 1...3: return .expiringSoon
    default: return .fresh
    }
}
```

### Pattern 4: Moving Items Across Dates

```swift
func moveItem(from: Date, to: Date) async throws {
    // Always use DateHelper for date comparison
    if DateHelper.isSameDay(from, to) {
        // Same day - just update meal type
        return
    }

    // Different days - full move operation
    let fromStart = DateHelper.startOfDay(for: from)
    let toStart = DateHelper.startOfDay(for: to)

    // ... move logic
}
```

---

## Debugging Tips

### Debug Date in Multiple Formats
```swift
#if DEBUG
DateHelper.debugDate(someDate, label: "Problem Date")
// Prints local time, UTC time, and timestamp
#endif
```

### Verify Firebase Query Boundaries
```swift
#if DEBUG
let (start, end) = DateHelper.firebaseDayBoundaries(for: date)
print("Query range:")
print("  Start: \(start) (\(DateHelper.localDateKey(for: start)))")
print("  End:   \(end) (\(DateHelper.localDateKey(for: end)))")
#endif
```

### Check Notification Timing
```swift
#if DEBUG
if let interval = DateHelper.timeIntervalUntil(date: date, hour: 9, minute: 0) {
    print("Notification fires in \(Int(interval/3600)) hours")
}
#endif
```

---

## What NOT to Do

### ❌ Never Use Raw Timestamp Arithmetic
```swift
// ❌ WRONG - Breaks during DST
let tomorrow = Date(timeIntervalSinceNow: 86400)

// ❌ WRONG - Not a full day during DST
let yesterday = date.addingTimeInterval(-24 * 3600)

// ✅ CORRECT
let tomorrow = DateHelper.addDays(1, to: Date())
```

### ❌ Never Compare Dates Directly for "Same Day"
```swift
// ❌ WRONG - Compares exact timestamps
if date1 == date2 { }

// ❌ WRONG - Still compares timestamps
if date1 < date2 { }

// ✅ CORRECT for same-day check
if DateHelper.isSameDay(date1, date2) { }

// ✅ CORRECT for chronological order
if date1 < date2 { } // This is fine for ordering
```

### ❌ Never Create DateFormatter Without Timezone
```swift
// ❌ WRONG - Timezone undefined
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"

// ✅ CORRECT
let formatter = DateHelper.localDateFormatter(format: "yyyy-MM-dd")
```

### ❌ Never Use Calendar Directly
```swift
// ❌ DON'T - Use DateHelper instead
let calendar = Calendar.current
let startOfDay = calendar.startOfDay(for: date)

// ✅ DO
let startOfDay = DateHelper.startOfDay(for: date)
```

**Exception**: You may use `Calendar.current` when DateHelper doesn't provide the specific method you need, but document which timezone you're using.

---

## Key Principles

1. **Local for Users**: Diary entries, notifications, display = local timezone
2. **UTC for Server**: Firebase stores UTC, but query by local day boundaries
3. **Calendar for Math**: Always use Calendar API for date arithmetic (via DateHelper)
4. **Document Context**: Add comment stating which timezone a Date represents

---

## Examples in Context

### Example: Add Diary Entry
```swift
func addDiaryEntry(_ item: DiaryFoodItem, date: Date) {
    // Store with local date key for grouping
    let key = DateHelper.localDateKey(for: date)
    entries[key, default: []].append(item)

    // Sync to Firebase (Firebase converts to UTC automatically)
    await FirebaseManager.shared.saveFoodEntry(item.toFoodEntry(date: date))
}
```

### Example: Load Diary for Date
```swift
func loadDiary(for date: Date) async throws -> [DiaryFoodItem] {
    // Query Firebase by local day boundaries
    let (start, end) = DateHelper.firebaseDayBoundaries(for: date)

    let entries = try await db.collection("entries")
        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
        .whereField("date", isLessThan: Timestamp(date: end))
        .getDocuments()

    return entries.documents.compactMap { try? $0.data(as: DiaryFoodItem.self) }
}
```

### Example: Schedule Use-By Notification
```swift
func scheduleExpiryNotification(for item: UseByItem) async {
    // Calculate days in local timezone
    let daysUntil = DateHelper.daysUntilExpiry(expiryDate: item.expiryDate)

    guard daysUntil >= 0 else { return } // Already expired

    // Schedule at 9 AM local time
    guard let interval = DateHelper.timeIntervalUntil(
        date: item.expiryDate,
        hour: 9,
        minute: 0
    ) else { return }

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: interval,
        repeats: false
    )

    // ... create and schedule notification
}
```

---

## Migration Checklist

When adding new date-related features:

- [ ] Identify if dates represent local time or UTC
- [ ] Use DateHelper for all date operations
- [ ] Document timezone context in comments
- [ ] Test across DST boundaries
- [ ] Test with different timezones
- [ ] Test midnight boundary cases
- [ ] Add debug logging if complex

---

## Files to Reference

- **DateHelper**: `/NutraSafe Beta/Utils/DateHelper.swift`
- **Summary**: `/TIMEZONE_FIXES_SUMMARY.md`
- **Testing**: `/TIMEZONE_TESTING_GUIDE.md`

---

**Remember**: When in doubt, use DateHelper. It handles all the edge cases.
