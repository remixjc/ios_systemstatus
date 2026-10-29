import WidgetKit
import SwiftUI

struct StatusWidgetEntry: TimelineEntry {
    let date: Date
    let reading: WidgetReading
    let preferences: WidgetPreferences
}

struct StatusWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StatusWidgetEntry {
        StatusWidgetEntry(date: Date(), reading: .placeholder, preferences: .init())
    }

    func snapshot(for configuration: StatusWidgetIntent, in context: Context) async -> StatusWidgetEntry {
        await entry(configuration)
    }

    func timeline(for configuration: StatusWidgetIntent, in context: Context) async -> Timeline<StatusWidgetEntry> {
        let current = await entry(configuration)
        // Scheduled entries expire foreground samples even if iOS delays the next reload.
        var entries = [current]
        if let snapshot = current.reading.appSnapshot, snapshot.isFresh(at: current.date) {
            entries.append(StatusWidgetEntry(date: snapshot.date.addingTimeInterval(300),
                                             reading: current.reading, preferences: current.preferences))
        }
        return Timeline(entries: entries, policy: .after(current.date.addingTimeInterval(30 * 60)))
    }

    @MainActor private func entry(_ configuration: StatusWidgetIntent) -> StatusWidgetEntry {
        StatusWidgetEntry(date: Date(), reading: .current(),
                          preferences: configuration.resolved(defaults: WidgetStore.preferences()))
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatusWidgetEntry
    private var size: WidgetSize {
        switch family {
        case .systemMedium: .medium
        case .systemLarge: .large
        default: .small
        }
    }

    var body: some View {
        WidgetDashboardView(reading: entry.reading, preferences: entry.preferences, size: size, date: entry.date)
            .containerBackground(for: .widget) { entry.preferences.background }
    }
}

@main
struct SystemStatusWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetStore.kind, intent: StatusWidgetIntent.self,
                               provider: StatusWidgetProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("系统状态")
        .description("电池、内存、存储与温度状态随手可见，自选指标和配色。CPU、网速为 App 采样快照。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // Disk capacity is for display on this device only (privacy reason E174.1).
        .disfavoredLocations([.iPhoneWidgetsOnMac], for: [.systemSmall, .systemMedium, .systemLarge])
    }
}
