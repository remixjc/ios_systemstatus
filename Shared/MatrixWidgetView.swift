import SwiftUI

/// A dense rounded-tile layout, with the same data provenance as the basic style.
struct MatrixWidgetView: View {
    let reading: WidgetReading
    let preferences: WidgetPreferences
    let size: WidgetSize
    let date: Date
    private var accent: Color { preferences.accent.color }
    private let tileColor = Color.white.opacity(0.085)

    var body: some View {
        VStack(spacing: 5) {
            if size == .small {
                smallBoard
            } else if size == .medium {
                compactBoard
            } else {
                largeBoard
            }
            HStack(spacing: 3) {
                Image(systemName: reading.isSimulator ? "desktopcomputer" : "clock")
                Text(reading.isSimulator ? "模拟器预览" : "读取")
                Text(reading.date, style: .time).monospacedDigit()
                Spacer(minLength: 0)
                if let snapshot = reading.appSnapshot, snapshot.isFresh(at: date) {
                    Text("App")
                    Text(snapshot.date, style: .time).monospacedDigit()
                } else {
                    Text("App 数据待更新")
                }
            }.font(.system(size: 8)).foregroundStyle(.white.opacity(0.5))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .environment(\.locale, Locale(identifier: "zh_CN"))
        .dynamicTypeSize(.small ... .large)
    }

    private var smallBoard: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Text(date, format: .dateTime.month().day().weekday(.abbreviated))
                    .font(.system(size: 10))
                Spacer(minLength: 0)
                if preferences.showClock { Text(date, style: .time).font(.system(size: 12, weight: .semibold)) }
            }.lineLimit(1).minimumScaleFactor(0.7)
            metricTile(preferences.primary, fontSize: 25)
                .frame(maxHeight: .infinity)
            HStack(spacing: 4) {
                Image(systemName: preferences.second.symbol).foregroundStyle(accent)
                Text(preferences.second.title)
                Spacer(minLength: 0)
                Text(reading.value(for: preferences.second, at: date)).fontWeight(.semibold)
            }.font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    /// Medium widgets closely follow the horizontal reference: date/storage on the left,
    /// connection/clock/device in the middle, battery/metrics/device outline on the right.
    private var compactBoard: some View {
        GeometryReader { geometry in
            let columnSpace: CGFloat = 5
            let available = geometry.size.width - columnSpace * 2
            let left = available * 0.19
            let center = available * 0.43
            let right = available * 0.38
            HStack(spacing: columnSpace) {
                VStack(spacing: 5) {
                    dateTile(compact: true).frame(maxHeight: .infinity)
                    storageTile(compact: true).frame(maxHeight: .infinity)
                }.frame(width: left)
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        connectionTile.frame(maxWidth: .infinity)
                        clockTile.frame(maxWidth: .infinity)
                    }.frame(maxHeight: .infinity)
                    deviceTile(compact: true).frame(maxHeight: .infinity)
                    HStack(spacing: 5) {
                        metricTile(preferences.third, fontSize: 13, compact: true)
                        metricTile(preferences.fourth, fontSize: 13, compact: true)
                    }.frame(maxHeight: .infinity)
                }.frame(width: center)
                VStack(spacing: 5) {
                    batteryPill.frame(height: max(20, geometry.size.height * 0.23))
                    HStack(spacing: 5) {
                        VStack(spacing: 5) {
                            metricTile(preferences.primary, fontSize: 13, compact: true)
                            metricTile(preferences.second, fontSize: 13, compact: true)
                        }.frame(maxWidth: .infinity)
                        phoneTile.frame(maxWidth: .infinity)
                    }.frame(maxHeight: .infinity)
                }.frame(width: right)
            }
        }
    }

    private var largeBoard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                dateTile(compact: false).frame(width: 83)
                VStack(spacing: 8) {
                    clockTile
                    batteryPill.frame(height: 30)
                }
            }.frame(height: 83)
            HStack(spacing: 8) {
                storageTile(compact: false).frame(width: 83)
                deviceTile(compact: false)
                phoneTile.frame(width: 56)
            }.frame(height: 81)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    metricTile(preferences.primary, fontSize: 22)
                    metricTile(preferences.second, fontSize: 22)
                }
                GridRow {
                    metricTile(preferences.third, fontSize: 22)
                    metricTile(preferences.fourth, fontSize: 22)
                }
            }.frame(maxHeight: .infinity)
        }
    }

    private func dateTile(compact: Bool) -> some View {
        VStack(spacing: compact ? 0 : 2) {
            Text(date, format: .dateTime.year().month())
                .font(.system(size: compact ? 7 : 9))
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: compact ? 24 : 35, weight: .medium, design: .rounded))
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: compact ? 8 : 11))
        }.lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: compact ? 12 : 18))
    }

    private func storageTile(compact: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: compact ? 3 : 4)
                Circle().trim(from: 0, to: reading.disk?.fraction ?? 0)
                    .stroke(accent, style: StrokeStyle(lineWidth: compact ? 3 : 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "internaldrive").font(.system(size: compact ? 13 : 18))
            }.frame(width: compact ? 25 : 34, height: compact ? 25 : 34)
            Text(reading.disk.map { Format.bytes($0.used) } ?? "—")
            Text(reading.disk.map { "/ \(Format.bytes($0.total))" } ?? "存储不可用")
                .foregroundStyle(.white.opacity(0.6))
        }.font(.system(size: compact ? 7 : 9)).lineLimit(1).minimumScaleFactor(0.6)
            .padding(compact ? 3 : 6).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: compact ? 12 : 18))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("存储，已用 \(reading.disk.map { Format.bytes($0.used) } ?? "不可用")，总容量 \(reading.disk.map { Format.bytes($0.total) } ?? "不可用")")
    }

    private var clockTile: some View {
        Group {
            if preferences.showClock {
                Text(date, style: .time)
                    .font(.system(size: size == .large ? 31 : 22, weight: .medium, design: .rounded))
                    .monospacedDigit()
            } else {
                Label("本机状态", systemImage: "waveform.path.ecg").font(.system(size: 10))
            }
        }.lineLimit(1).minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: size == .large ? 18 : 12))
    }

    private var batteryPill: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(tileColor)
                if let battery = reading.battery {
                    Capsule().fill(Color.green.opacity(0.9))
                        .frame(width: geometry.size.width * min(1, max(0, battery)))
                }
                HStack(spacing: 4) {
                    Image(systemName: reading.charging ? "battery.100percent.bolt" : "battery.75percent")
                    Text(reading.battery.map(Format.percent) ?? "—")
                }.font(.system(size: size == .large ? 19 : 16, weight: .medium))
                    .padding(.horizontal, 9).lineLimit(1).minimumScaleFactor(0.6)
            }
        }.accessibilityElement(children: .combine)
            .accessibilityLabel("电量 \(reading.battery.map(Format.percent) ?? "不可用")")
    }

    private var connectionTile: some View {
        VStack(spacing: 2) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14)).foregroundStyle(accent)
            Text(reading.value(for: .connection, at: date))
                .font(.system(size: 8)).lineLimit(1).minimumScaleFactor(0.6)
            Text("App 快照").font(.system(size: 6)).foregroundStyle(.white.opacity(0.5))
        }.padding(3).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("网络连接，\(reading.value(for: .connection, at: date))，App 采样快照")
    }

    private func deviceTile(compact: Bool) -> some View {
        let device = DeviceIdentity.current
        return VStack(spacing: compact ? 2 : 5) {
            Text(device.modelName).font(.system(size: compact ? 10 : 13, weight: .medium))
                .lineLimit(2)
            Text(device.chipName ?? "芯片暂未收录")
                .font(.system(size: compact ? 10 : 18, weight: .semibold))
        }.lineLimit(1).minimumScaleFactor(0.6)
            .padding(4).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: compact ? 12 : 18))
    }

    private var phoneTile: some View {
        VStack(spacing: 3) {
            GeometryReader { geometry in
                let width = min(geometry.size.width * 0.8, geometry.size.height * 0.51)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.85), lineWidth: 1.4)
                    Capsule().fill(.white.opacity(0.85)).frame(width: width * 0.4, height: 3).padding(.top, 3)
                    VStack {
                        Spacer()
                        Capsule().fill(.white.opacity(0.85)).frame(width: width * 0.45, height: 2).padding(.bottom, 3)
                    }
                }.frame(width: width).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text("iOS \(UIDevice.current.systemVersion)")
                .font(.system(size: 7)).lineLimit(1).minimumScaleFactor(0.6)
        }.padding(5).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileColor, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
    }

    private func metricTile(_ metric: WidgetMetric, fontSize: CGFloat, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 3) {
            HStack(spacing: 3) {
                Image(systemName: metric.symbol)
                Text(metric.title)
            }.font(.system(size: compact ? 7 : 9)).foregroundStyle(accent)
            Text(reading.value(for: metric, at: date))
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            if !compact {
                Text(reading.detail(for: metric, at: date))
                    .font(.system(size: 8)).foregroundStyle(.white.opacity(0.6))
            } else if metric.usesAppSnapshot {
                Text(reading.value(for: metric, at: date) == "—" ? "打开 App" : "App 快照")
                    .font(.system(size: 6)).foregroundStyle(.white.opacity(0.6))
            }
        }.lineLimit(1).minimumScaleFactor(0.5)
            .padding(compact ? 5 : 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(tileColor, in: RoundedRectangle(cornerRadius: compact ? 12 : 16))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(metric.title)，\(reading.value(for: metric, at: date))，\(reading.detail(for: metric, at: date))")
    }
}
