#if false
//
//  FastingAccessoryInlineWidget.swift
//  NutraSafeWidgets
//
//  A thin, elegant Accessory Inline widget that shows a "Fast Timer" label
//  and a live countdown when an active fasting session is detected.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct FastingAccessoryInlineProvider: TimelineProvider {
    struct Entry: TimelineEntry {
        let date: Date
        let isActive: Bool
        let endDate: Date?
    }

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), isActive: true, endDate: Date().addingTimeInterval(60 * 60))
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = loadEntry()

        // Refresh frequently when active, otherwise less often
        let refresh: Date
        if entry.isActive, let end = entry.endDate {
            // Update every 30 seconds while counting down, or stop after end time
            let next = min(Date().addingTimeInterval(30), end.addingTimeInterval(5))
            refresh = next
        } else {
            refresh = Date().addingTimeInterval(60 * 30)
        }

        let timeline = Timeline(entries: [entry], policy: .after(refresh))
        completion(timeline)
    }

    // MARK: - Data Loading
    private func loadEntry() -> Entry {
        let appGroupId = "group.com.nutrasafe.beta"
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: "fastingSessionData"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return Entry(date: Date(), isActive: false, endDate: nil)
        }

        let isActive = (json["isActive"] as? Bool) ?? false
        if isActive,
           let startTs = json["startTime"] as? TimeInterval,
           let targetHours = json["targetDurationHours"] as? Int {
            let start = Date(timeIntervalSince1970: startTs)
            let end = start.addingTimeInterval(TimeInterval(targetHours * 3600))
            return Entry(date: Date(), isActive: true, endDate: end)
        } else {
            return Entry(date: Date(), isActive: false, endDate: nil)
        }
    }
}

// MARK: - Widget View
struct FastingAccessoryInlineEntryView: View {
    var entry: FastingAccessoryInlineProvider.Entry

    var body: some View {
        // "Thin line" style: a compact, elegant row with icon, title, and optional timer
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .semibold))

            Text("Fast Timer")
                .font(.system(size: 12, weight: .semibold))

            if entry.isActive, let end = entry.endDate, end > Date() {
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .allowsTightening(true)
    }
}

// MARK: - Widget Definition
struct FastingAccessoryInlineWidget: Widget {
    let kind: String = "FastingAccessoryInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingAccessoryInlineProvider()) { entry in
            FastingAccessoryInlineEntryView(entry: entry)
        }
        .configurationDisplayName("Fast Timer")
        .description("A sleek inline widget that shows your fasting countdown.")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Previews
#Preview("Accessory Inline - Active") {
    FastingAccessoryInlineEntryView(
        entry: FastingAccessoryInlineProvider.Entry(
            date: Date(),
            isActive: true,
            endDate: Date().addingTimeInterval(60 * 45)
        )
    )
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}

#Preview("Accessory Inline - Idle") {
    FastingAccessoryInlineEntryView(
        entry: FastingAccessoryInlineProvider.Entry(
            date: Date(),
            isActive: false,
            endDate: nil
        )
    )
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}
#endif

