import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("showSeconds") private var showSeconds = false
    @State private var showSettings = false
    @State private var showClock = false
    @State private var selected: Metric?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 14) {
                        clockHeader(wide: geometry.size.width > 760)
                            .padding(.bottom, 3)
                        #if targetEnvironment(simulator)
                        Label("模拟器环境 · 数据不代表 iPhone 实际性能", systemImage: "desktopcomputer")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        #endif
                        let wide = geometry.size.width > 760 && !dynamicType.isAccessibilitySize
                        if wide {
                            HStack(alignment: .top, spacing: 14) {
                                cpuButton
                                networkButton
                            }
                        } else {
                            cpuButton
                            networkButton
                        }
                        LazyVGrid(columns: columns(count: dynamicType.isAccessibilitySize || geometry.size.width < 340 ? 1 : 2), spacing: 14) {
                            metricButton(.memory) { memoryCard }
                            metricButton(.storage) { diskCard }
                        }
                        let count = dynamicType.isAccessibilitySize ? 1 : geometry.size.width > 760 ? 3 : geometry.size.width < 370 ? 2 : 3
                        LazyVGrid(columns: columns(count: count), spacing: 14) {
                            metricButton(.battery) {
                                SmallMetricCard(title: "电池", icon: "battery.75percent",
                                    value: monitor.battery.map(Format.percent) ?? "—",
                                    subtitle: monitor.charging, color: Palette.green, gauge: monitor.battery)
                            }
                            metricButton(.thermal) {
                                SmallMetricCard(title: "状态", icon: "thermometer.medium", value: monitor.thermalText,
                                    subtitle: monitor.lowPower ? "低电量模式" : "标准模式",
                                    color: monitor.thermal.rawValue >= 2 ? Palette.orange : Palette.green)
                            }
                            metricButton(.session) {
                                SmallMetricCard(title: "监测", icon: "timer",
                                    value: Format.duration(monitor.now.timeIntervalSince(monitor.startedAt)),
                                    subtitle: monitor.paused ? "采样已暂停" : "本次打开时长")
                            }
                            metricButton(.brightness) {
                                SmallMetricCard(title: "亮度", icon: "sun.max",
                                    value: Format.percent(monitor.brightness), subtitle: "当前屏幕",
                                    color: Palette.yellow, gauge: monitor.brightness)
                            }
                            metricButton(.audio) {
                                SmallMetricCard(title: "音量", icon: "headphones",
                                    value: Format.percent(monitor.volume), subtitle: monitor.audioRoute,
                                    color: Palette.blue, gauge: monitor.volume)
                            }
                            metricButton(.device) {
                                SmallMetricCard(title: "设备", icon: "iphone",
                                    value: UIDevice.current.model, subtitle: "iOS \(UIDevice.current.systemVersion)")
                            }
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "lock.shield")
                            Text("数据留在设备 · 无广告 · 无追踪")
                        }
                        .font(.caption2).foregroundStyle(.secondary).padding(.vertical, 14)
                    }
                    .frame(maxWidth: 1150)
                    .padding(.horizontal, geometry.size.width < 400 ? 14 : 22)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                }
                .background(Palette.background)
            }
            .navigationTitle("系统状态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("设置").accessibilityIdentifier("settingsButton")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { monitor.togglePause() } label: {
                        Image(systemName: monitor.paused ? "play.fill" : "pause.fill")
                    }
                    .accessibilityLabel(monitor.paused ? "继续采样" : "暂停采样")
                    .accessibilityIdentifier("pauseButton")
                    Button { showClock = true } label: { Image(systemName: "clock") }
                        .accessibilityLabel("专注时钟")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $selected) { MetricDetailView(metric: $0) }
            .fullScreenCover(isPresented: $showClock) {
                FocusClockView().environmentObject(monitor)
            }
        }
    }

    private func columns(count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: count)
    }

    private func metricButton<Content: View>(_ metric: Metric, @ViewBuilder content: () -> Content) -> some View {
        Button { selected = metric } label: { content().frame(maxWidth: .infinity) }
            .buttonStyle(.plain)
            .accessibilityHint("打开\(metric.title)详情")
            .accessibilityIdentifier("metric-\(metric.rawValue)")
    }

    private func clockHeader(wide: Bool) -> some View {
        VStack(spacing: 6) {
            Text(clockString(monitor.now, use24Hour: use24Hour, seconds: showSeconds))
                .font(.system(size: wide ? 88 : showSeconds ? 64 : 80, weight: .bold, design: .rounded))
                .tracking(-4).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityIdentifier("dashboardClock")
            Text(monitor.now.formatted(.dateTime.locale(Locale(identifier: "zh_CN")).month(.twoDigits).day(.twoDigits).weekday(.wide)))
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(Palette.blue)
            ViewThatFits {
                statusLine
                VStack(spacing: 5) {
                    Label(monitor.paused ? "采样已暂停" : "实时监测中", systemImage: "circle.fill")
                    Text("\(monitor.connection) · 电量 \(monitor.battery.map(Format.percent) ?? "不可用")")
                }.font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
    }

    private var statusLine: some View {
        HStack(spacing: 6) {
            Circle().fill(monitor.paused ? Palette.orange : Palette.green).frame(width: 7, height: 7)
            Text("\(monitor.paused ? "已暂停" : monitor.thermalText) · \(monitor.connection) · 电量 \(monitor.battery.map(Format.percent) ?? "不可用")")
                .font(.subheadline).foregroundStyle(.secondary)
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var cpuButton: some View {
        metricButton(.cpu) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    CardHeading(title: "CPU", icon: "cpu", color: Palette.blue, subtitle: "60 秒")
                    VStack(alignment: .trailing, spacing: 3) {
                        Legend(color: Palette.cyan, text: "用户 \(monitor.cpu.map { "\(Int($0.user.rounded()))%" } ?? "—")")
                        Legend(color: Palette.blue, text: "系统 \(monitor.cpu.map { "\(Int($0.system.rounded()))%" } ?? "—")")
                    }.fixedSize()
                }
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monitor.cpu.map { "\(Int($0.total.rounded()))%" } ?? "—")
                            .font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
                        Text("\(ProcessInfo.processInfo.processorCount) 核心").font(.caption).foregroundStyle(.secondary)
                        Text(monitor.cpu == nil ? "等待 / 系统受限" : "实时使用率")
                            .font(.caption2).foregroundStyle(Palette.blue)
                    }.frame(width: 98, alignment: .leading)
                    LiveChart(points: monitor.cpuHistory, now: monitor.now, ceiling: 100,
                              colors: [Palette.cyan, Palette.blue], label: { "\(Int($0))" })
                }
            }.cardSurface()
        }
    }

    private var networkButton: some View {
        metricButton(.network) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    CardHeading(title: "网络", icon: "wifi", color: Palette.green, subtitle: "60 秒")
                    VStack(alignment: .trailing, spacing: 3) {
                        Legend(color: Palette.green, text: "↓ " + Format.rate(monitor.download))
                        Legend(color: Palette.cyan, text: "↑ " + Format.rate(monitor.upload))
                    }.fixedSize()
                }
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Format.rate(monitor.download))
                            .font(.system(size: 26, weight: .bold, design: .rounded)).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text(monitor.connection).font(.caption).foregroundStyle(.secondary)
                        Text("↓ " + Format.bytes(Double(monitor.received)))
                            .font(.caption2).foregroundStyle(Palette.green)
                    }.frame(width: 98, alignment: .leading)
                    LiveChart(points: monitor.networkHistory, now: monitor.now,
                              ceiling: max(1024, monitor.networkHistory.map { max($0.first, $0.second) }.max() ?? 0),
                              colors: [Palette.green, Palette.cyan], label: { Format.bytes($0) })
                }.frame(minHeight: 71)
            }.cardSurface()
        }
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CardHeading(title: "内存", icon: "memorychip", color: .white)
                Text(monitor.memory.map { Format.percent($0.fraction) } ?? "—")
                    .font(.system(.title2, design: .rounded, weight: .bold)).monospacedDigit()
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Legend(color: .red, text: "联动 " + (monitor.memory.map { Format.bytes($0.wired) } ?? "—"))
                    Legend(color: Palette.blue, text: "活跃 " + (monitor.memory.map { Format.bytes($0.active) } ?? "—"))
                    Legend(color: Palette.yellow, text: "非活跃 " + (monitor.memory.map { Format.bytes($0.inactive) } ?? "—"))
                    Legend(color: .gray, text: "空闲 " + (monitor.memory.map { Format.bytes($0.free) } ?? "—"))
                }
                Spacer(minLength: 0)
                if let m = monitor.memory {
                    RingChart(values: [(m.wired, .red), (m.active, Palette.blue), (m.inactive, Palette.yellow),
                                       (m.compressed, .purple), (m.free, .gray)], lineWidth: 9)
                        .frame(width: 48, height: 48)
                }
            }
        }.frame(maxWidth: .infinity, minHeight: 110, alignment: .top).cardSurface()
    }

    private var diskCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CardHeading(title: "存储", icon: "internaldrive", color: .white)
                Text(monitor.disk.map { Format.percent($0.fraction) } ?? "—")
                    .font(.system(.title2, design: .rounded, weight: .bold)).monospacedDigit()
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 7) {
                    Legend(color: Palette.orange, text: "已用 " + (monitor.disk.map { Format.bytes($0.used) } ?? "—"))
                    Legend(color: .gray, text: "可用 " + (monitor.disk.map { Format.bytes($0.available) } ?? "—"))
                    Text("设备内显示").font(.caption2).foregroundStyle(.secondary).padding(.top, 3)
                }
                Spacer(minLength: 0)
                if let disk = monitor.disk {
                    RingChart(values: [(disk.used, Palette.orange), (disk.available, .gray)], lineWidth: 9)
                        .frame(width: 48, height: 48)
                }
            }
        }.frame(maxWidth: .infinity, minHeight: 110, alignment: .top).cardSurface()
    }
}

func clockString(_ date: Date, use24Hour: Bool, seconds: Bool) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = use24Hour ? (seconds ? "HH:mm:ss" : "HH:mm") : (seconds ? "a h:mm:ss" : "a h:mm")
    return formatter.string(from: date)
}

struct FocusClockView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.dismiss) private var dismiss
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("showSeconds") private var showSeconds = false
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                HStack {
                    Text("系统状态").foregroundStyle(.secondary)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title) }
                        .accessibilityLabel("退出专注时钟")
                }
                Spacer()
                Text(clockString(monitor.now, use24Hour: use24Hour, seconds: showSeconds))
                    .font(.system(size: min(geometry.size.width * 0.23, 180), weight: .bold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
                Text(monitor.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title3).foregroundStyle(Palette.blue)
                Text("\(monitor.connection) · \(monitor.thermalText) · \(monitor.battery.map(Format.percent) ?? "电量不可用")")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("常亮选项可在设置中开启").font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.background)
        }
    }
}
