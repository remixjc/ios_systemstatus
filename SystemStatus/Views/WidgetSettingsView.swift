import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @State private var preferences = WidgetStore.preferences()
    @State private var size: WidgetSize = .medium
    @State private var saveFailed = false

    var body: some View {
        Form {
            Section {
                Picker("小组件样式", selection: $preferences.style) {
                    ForEach(WidgetStyle.allCases) { Text($0.title).tag($0) }
                }.accessibilityIdentifier("widgetStylePicker")
                Picker("预览尺寸", selection: $size) {
                    ForEach(WidgetSize.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented).accessibilityIdentifier("widgetPreviewSize")
                GeometryReader { geometry in
                    let scale = min(1, geometry.size.width / size.previewSize.width)
                    HStack {
                        Spacer(minLength: 0)
                        WidgetDashboardView(reading: previewReading, preferences: preferences, size: size, date: monitor.now)
                            .padding(14)
                            .frame(width: size.previewSize.width, height: size.previewSize.height)
                            .background(preferences.background, in: RoundedRectangle(cornerRadius: 24))
                            .scaleEffect(scale, anchor: .top)
                            .frame(width: size.previewSize.width * scale, height: size.previewSize.height * scale)
                            .accessibilityIdentifier("widgetPreview")
                        Spacer(minLength: 0)
                    }
                }
                .frame(height: size.previewSize.height)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                .listRowBackground(Color.clear)
            } header: { Text("桌面预览") } footer: {
                Text(preferences.style == .standard
                     ? "基础款：小号显示主指标；中号显示前两项；大号显示四项及可选时钟。"
                     : "信息矩阵：组合日期、时钟、电量条、存储环形图、设备信息与自选指标。中号、大号显示四项；小号显示前两项。")
            }
            Section("默认展示内容") {
                metricPicker("主指标", selection: $preferences.primary)
                metricPicker("第二项", selection: $preferences.second)
                metricPicker("第三项", selection: $preferences.third)
                metricPicker("第四项", selection: $preferences.fourth)
            }
            Section("外观") {
                Picker("主题配色", selection: $preferences.accent) {
                    ForEach(WidgetAccent.allCases) { Text($0.title).tag($0) }
                }
                Toggle("显示时钟", isOn: $preferences.showClock)
            }
            Section {
                Label("长按主屏幕空白处，选择“编辑 → 添加小组件”。", systemImage: "1.circle")
                Label("搜索“系统状态”，选择小号、中号或大号并添加。", systemImage: "2.circle")
                Label("长按已添加的小组件，选择“编辑小组件”，可单独设置每一项。", systemImage: "3.circle")
                Text("选择“跟随 App 设置”的项目使用这里的默认值；你也可以添加多个小组件，分别设置不同指标和配色。")
            } header: { Text("添加与独立设置") }
            Section {
                Text("小组件由 iOS 安排刷新，不会每秒采样。电池、内存、存储与温度状态在系统刷新时读取；底部显示该次读取时间。")
                Text("CPU、网速、网络连接、亮度、音量与本次监测只显示最近 5 分钟内的 App 前台快照，并标注时间。超过 5 分钟显示“打开 App 更新”，不会把旧值当作实时状态。")
                Text("信息矩阵通过本地对照表显示手机型号与芯片名称，未收录时保留硬件标识；本次监测是 App 打开时长，不是设备开机时长。蓝牙、蜂窝开关不作为可读取状态展示。")
                Text("点按桌面小组件可打开 App。存储容量只在本机显示，小组件不请求网络、不上传数据。")
                if saveFailed {
                    Text("共享设置保存失败，请重新打开 App 后重试。").foregroundStyle(.red)
                }
            } header: { Text("更新与数据说明") }
        }
        .navigationTitle("桌面小组件")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: preferences) { _, value in
            saveFailed = !WidgetStore.save(value)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetStore.kind)
        }
    }

    private func metricPicker(_ title: String, selection: Binding<WidgetMetric>) -> some View {
        Picker(title, selection: selection) {
            ForEach(WidgetMetric.allCases) { metric in
                Text(metric.title + (metric.usesAppSnapshot ? "（App 快照）" : "")).tag(metric)
            }
        }.accessibilityIdentifier("widgetMetric-\(title)")
    }

    private var previewReading: WidgetReading {
        WidgetReading(date: monitor.now, battery: monitor.battery,
                      charging: monitor.charging == "正在充电" || monitor.charging == "已充满",
                      memory: monitor.memory, disk: monitor.disk, thermal: monitor.thermalText,
                      lowPower: monitor.lowPower,
                      appSnapshot: monitor.widgetSnapshot,
                      isSimulator: {
                          #if targetEnvironment(simulator)
                          true
                          #else
                          false
                          #endif
                      }())
    }
}
