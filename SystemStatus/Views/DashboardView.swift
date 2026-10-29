import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("showSeconds") private var showSeconds = false
    @State private var showSettings = false
    @State private var showClock = false
    @State private var selected: Metric?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let landscape = geometry.size.width > geometry.size.height
                let referenceHeight: CGFloat = landscape ? 360 : 760
                let referenceWidth: CGFloat = landscape ? 780 : 375
                let scale = max(0.01, min(1.15, geometry.size.height / referenceHeight,
                                         geometry.size.width / referenceWidth))
                dashboard(landscape: landscape)
                    .dynamicTypeSize(.medium)
                    .frame(width: geometry.size.width / scale, height: geometry.size.height / scale)
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
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

    /// Size the complete dashboard against the safe-area viewport, including short phones.
    /// Detail sheets retain the user's preferred text size for comfortable reading.
    private func dashboard(landscape: Bool) -> some View {
        VStack(spacing: 8) {
            if landscape {
                HStack(spacing: 10) {
                    clockHeader(wide: true).frame(width: 210)
                    cpuButton
                    networkButton
                }
                HStack(alignment: .top, spacing: 10) {
                    capacityGrid.frame(maxWidth: .infinity)
                    smallGrid.frame(maxWidth: .infinity)
                }
            } else {
                clockHeader(wide: false).frame(height: 140)
                cpuButton
                networkButton
                capacityGrid
                smallGrid
            }
            footer
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: 1200, maxHeight: .infinity, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var capacityGrid: some View {
        HStack(spacing: 8) {
            metricButton(.memory) { memoryCard }
            metricButton(.storage) { diskCard }
        }
    }

    private var smallGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
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
                    value: monitor.volume.map(Format.percent) ?? "—", subtitle: monitor.audioRoute,
                    color: Palette.blue, gauge: monitor.volume)
            }
            metricButton(.device) {
                SmallMetricCard(title: "设备", icon: "iphone",
                    value: monitor.device.modelName, subtitle: monitor.device.chipName ?? "芯片暂未收录",
                    valueFontSize: 14, valueLineLimit: 2)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            #if targetEnvironment(simulator)
            Image(systemName: "desktopcomputer")
            Text("模拟器读数仅供预览 · 无广告 · 无追踪")
            #else
            Image(systemName: "lock.shield")
            Text("数据留在设备 · 无广告 · 无追踪")
            #endif
        }
        .font(.system(size: 9)).foregroundStyle(.secondary)
        .lineLimit(1).minimumScaleFactor(0.7)
        .frame(height: 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dashboardFooter")
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
                .font(.system(size: wide ? 50 : showSeconds ? 62 : 78, weight: .bold, design: .rounded))
                .tracking(-4).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityIdentifier("dashboardClock")
            Text(monitor.now.formatted(.dateTime.locale(Locale(identifier: "zh_CN")).month(.twoDigits).day(.twoDigits).weekday(.wide)))
                .font(.system(size: 16, weight: .medium, design: .rounded))
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
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var cpuButton: some View {
        metricButton(.cpu) {
            VStack(alignment: .leading, spacing: 6) {
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
                            .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
                        Text("\(ProcessInfo.processInfo.processorCount) 核心").font(.caption).foregroundStyle(.secondary)
                        Text(monitor.cpu == nil ? "等待 / 系统受限" : "实时使用率")
                            .font(.caption2).foregroundStyle(Palette.blue)
                    }.frame(width: 94, alignment: .leading)
                    LiveChart(points: monitor.cpuHistory, now: monitor.now, ceiling: 100,
                              colors: [Palette.cyan, Palette.blue], label: { "\(Int($0))" })
                }
            }.cardSurface()
        }
    }

    private var networkButton: some View {
        metricButton(.network) {
            VStack(alignment: .leading, spacing: 6) {
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
                    }.frame(width: 94, alignment: .leading)
                    LiveChart(points: monitor.networkHistory, now: monitor.now,
                              ceiling: max(1024, monitor.networkHistory.map { max($0.first, $0.second) }.max() ?? 0),
                              colors: [Palette.green, Palette.cyan], label: { Format.bytes($0) })
                }
            }.cardSurface()
        }
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CardHeading(title: "内存", icon: "memorychip", color: .white)
                Text(monitor.memory.map { Format.percent($0.fraction) } ?? "—")
                    .font(.system(size: 23, weight: .bold, design: .rounded)).monospacedDigit()
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Legend(color: .red, text: "联动 " + (monitor.memory.map { Format.bytes($0.wired) } ?? "—"))
                    Legend(color: Palette.blue, text: "活跃 " + (monitor.memory.map { Format.bytes($0.active) } ?? "—"))
                    Legend(color: Palette.yellow, text: "非活跃 " + (monitor.memory.map { Format.bytes($0.inactive) } ?? "—"))
                    Legend(color: .gray, text: "空闲 " + (monitor.memory.map { Format.bytes($0.free) } ?? "—"))
                }
                Spacer(minLength: 0)
                if let m = monitor.memory {
                    RingChart(values: [(m.wired, .red), (m.active, Palette.blue), (m.inactive, Palette.yellow),
                                       (m.compressed, .purple), (m.free, .gray)], lineWidth: 9)
                        .frame(width: 42, height: 42)
                }
            }
        }.frame(maxWidth: .infinity, minHeight: 92, alignment: .top).cardSurface()
    }

    private var diskCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CardHeading(title: "存储", icon: "internaldrive", color: .white)
                Text(monitor.disk.map { Format.percent($0.fraction) } ?? "—")
                    .font(.system(size: 23, weight: .bold, design: .rounded)).monospacedDigit()
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Legend(color: Palette.orange, text: "已用 " + (monitor.disk.map { Format.bytes($0.used) } ?? "—"))
                    Legend(color: .gray, text: "可用 " + (monitor.disk.map { Format.bytes($0.available) } ?? "—"))
                    Text("设备内显示").font(.caption2).foregroundStyle(.secondary).padding(.top, 3)
                }
                Spacer(minLength: 0)
                if let disk = monitor.disk {
                    RingChart(values: [(disk.used, Palette.orange), (disk.available, .gray)], lineWidth: 9)
                        .frame(width: 42, height: 42)
                }
            }
        }.frame(maxWidth: .infinity, minHeight: 92, alignment: .top).cardSurface()
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
