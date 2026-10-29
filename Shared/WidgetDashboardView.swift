import SwiftUI

enum WidgetSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var title: String {
        switch self {
        case .small: "小号"
        case .medium: "中号"
        case .large: "大号"
        }
    }
    var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 158, height: 158)
        case .medium: CGSize(width: 338, height: 158)
        case .large: CGSize(width: 338, height: 354)
        }
    }
}

extension WidgetAccent {
    var color: Color {
        switch self {
        case .blue: Color(red: 0.12, green: 0.64, blue: 1)
        case .green: Color(red: 0.25, green: 0.87, blue: 0.64)
        case .purple: Color(red: 0.72, green: 0.52, blue: 1)
        case .orange: Color(red: 1, green: 0.64, blue: 0.23)
        }
    }
    var background: LinearGradient {
        LinearGradient(colors: [color.opacity(0.19), Color(red: 0.055, green: 0.065, blue: 0.11)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension WidgetPreferences {
    var background: LinearGradient {
        style == .standard ? accent.background :
            LinearGradient(colors: [Color(white: 0.09), Color(white: 0.035)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Shared by the real extension and the in-app preview.
struct WidgetDashboardView: View {
    let reading: WidgetReading
    let preferences: WidgetPreferences
    let size: WidgetSize
    let date: Date
    private var accent: Color { preferences.accent.color }

    @ViewBuilder var body: some View {
        if preferences.style == .matrix {
            MatrixWidgetView(reading: reading, preferences: preferences, size: size, date: date)
        } else {
            standardBody
        }
    }

    private var standardBody: some View {
        VStack(alignment: .leading, spacing: size == .large ? 12 : 8) {
            header
            if size == .small {
                smallMetric
            } else if size == .medium {
                HStack(alignment: .top, spacing: 14) {
                    tile(preferences.primary, prominent: true)
                    Rectangle().fill(.white.opacity(0.12)).frame(width: 1)
                    tile(preferences.second, prominent: true)
                }.frame(maxHeight: .infinity)
            } else {
                if preferences.showClock {
                    HStack(alignment: .firstTextBaseline) {
                        Text(date, style: .time)
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Spacer()
                        Text(date, format: .dateTime.month().day().weekday(.abbreviated))
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.65))
                    }.lineLimit(1).minimumScaleFactor(0.7)
                }
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        largeTile(preferences.primary)
                        largeTile(preferences.second)
                    }
                    GridRow {
                        largeTile(preferences.third)
                        largeTile(preferences.fourth)
                    }
                }.frame(maxHeight: .infinity)
            }
            footer
        }
        .foregroundStyle(.white)
        .font(.system(size: 11))
        .dynamicTypeSize(.small ... .large)
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "waveform.path.ecg").foregroundStyle(accent)
            Text("系统状态").fontWeight(.semibold)
            Spacer(minLength: 0)
            if size == .medium && preferences.showClock {
                Text(date, style: .time).monospacedDigit().foregroundStyle(.white.opacity(0.65))
            }
        }.lineLimit(1)
    }

    private var smallMetric: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(preferences.primary.title, systemImage: preferences.primary.symbol)
                .foregroundStyle(accent)
            HStack(alignment: .center, spacing: 4) {
                Text(reading.value(for: preferences.primary, at: date))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.4)
                Spacer(minLength: 0)
                if let fraction = reading.fraction(for: preferences.primary, at: date) {
                    ring(fraction).frame(width: 29, height: 29)
                }
            }
            Text(reading.detail(for: preferences.primary, at: date))
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.65))
                .lineLimit(1).minimumScaleFactor(0.7)
        }.frame(maxHeight: .infinity, alignment: .center)
    }

    private func tile(_ metric: WidgetMetric, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(metric.title, systemImage: metric.symbol).foregroundStyle(accent)
                .font(.system(size: 11, weight: .medium)).lineLimit(1)
            Text(reading.value(for: metric, at: date))
                .font(.system(size: prominent ? 27 : 25, weight: .bold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.4)
            if let fraction = reading.fraction(for: metric, at: date) {
                GeometryReader { geometry in
                    Capsule().fill(accent.opacity(0.16))
                        .overlay(alignment: .leading) {
                            Capsule().fill(accent).frame(width: geometry.size.width * min(1, max(0, fraction)))
                        }
                }.frame(height: 4)
            }
            Text(reading.detail(for: metric, at: date))
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.65))
                .lineLimit(1).minimumScaleFactor(0.65)
        }.frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func largeTile(_ metric: WidgetMetric) -> some View {
        tile(metric, prominent: false)
            .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
    }

    private func ring(_ fraction: Double) -> some View {
        ZStack {
            Circle().stroke(accent.opacity(0.18), lineWidth: 4)
            Circle().trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private var footer: some View {
        HStack(spacing: 3) {
            Image(systemName: reading.isSimulator ? "desktopcomputer" : "clock")
            if reading.isSimulator {
                Text("模拟器读数仅供预览")
            } else {
                Text("更新")
                Text(reading.date, style: .time).monospacedDigit()
            }
            Spacer(minLength: 0)
            if size == .large {
                Text("点按打开 App").foregroundStyle(accent)
            }
        }.font(.system(size: 9)).foregroundStyle(.white.opacity(0.5))
            .lineLimit(1).minimumScaleFactor(0.7)
    }
}
