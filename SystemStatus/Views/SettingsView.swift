import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.dismiss) private var dismiss
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("showSeconds") private var showSeconds = false
    @AppStorage("keepAwake") private var keepAwake = false
    @State private var confirmClear = false
    @State private var showReport = false
    var body: some View {
        NavigationStack {
            Form {
                Section("显示") {
                    Toggle("24 小时制", isOn: $use24Hour)
                    Toggle("显示秒数", isOn: $showSeconds)
                    Toggle("保持屏幕常亮", isOn: $keepAwake)
                }
                Section {
                    Picker("刷新间隔", selection: $monitor.interval) {
                        Text("0.5 秒").tag(0.5)
                        Text("1 秒").tag(1.0)
                        Text("2 秒").tag(2.0)
                    }
                    Button(monitor.paused ? "继续采样" : "暂停采样") { monitor.togglePause() }
                    Button("清空曲线与流量累计", role: .destructive) { confirmClear = true }
                } header: {
                    Text("采样")
                } footer: {
                    Text("曲线保留最近 60 秒。更短的刷新间隔会增加耗电；切换到后台后自动停止采样。")
                }
                Section("报告") {
                    Button { showReport = true } label: {
                        Label("预览并分享报告", systemImage: "square.and.arrow.up")
                    }.accessibilityIdentifier("reportButton")
                }
                Section("桌面") {
                    NavigationLink {
                        WidgetSettingsView()
                    } label: {
                        Label("桌面小组件", systemImage: "square.grid.2x2")
                    }.accessibilityIdentifier("widgetSettingsLink")
                }
                Section("隐私") {
                    NavigationLink("隐私政策") { PrivacyView() }
                    LabeledContent("广告与追踪", value: "无")
                    LabeledContent("数据上传", value: "无自动上传")
                    LabeledContent("第三方 SDK", value: "无")
                }
                Section("帮助与支持") {
                    NavigationLink("使用帮助与技术支持") { SupportView() }
                    Link("联系开发者", destination: SupportLinks.email)
                }
                Section {
                    LabeledContent("版本", value: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"))")
                    Text("系统状态是一款本地设备监测工具。指标仅反映公开接口可读取的信息，不提供硬件诊断结论。")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("关于系统状态") }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.accessibilityIdentifier("settingsDone")
                }
            }
            .confirmationDialog("清空最近曲线与本次流量累计？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { monitor.clearHistory() }
            }
            .sheet(isPresented: $showReport) { ReportView(report: monitor.report) }
        }
    }
}

struct ReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report).font(.system(.body, design: .monospaced))
                    .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding()
            }
            .navigationTitle("监测报告")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: report) { Label("分享", systemImage: "square.and.arrow.up") }
                }
            }
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("隐私政策").font(.largeTitle.bold())
                Text("生效日期：2026 年 10 月 28 日").foregroundStyle(.secondary)
                Text("系统状态在你的设备上读取和展示系统指标，不注册账号，不自动上传数据，不包含广告、分析或追踪 SDK。")
                Text("本地数据").font(.title3.bold())
                Text("刷新频率、时钟格式和常亮选项保存在应用本地。CPU、网络等最近 60 秒的曲线仅保存在内存中，退出进程后消失。为展示桌面小组件，应用与自己的小组件扩展在本机共享展示设置，以及最近一次 CPU、网速、网络连接、屏幕亮度、系统音量和本次监测时长的数值与采样时间；每次有效采样覆盖旧快照，不保存历史。快照超过 5 分钟不再展示数值。存储容量由应用或小组件各自在本机读取并展示，不写入共享快照，不包含在导出报告中。卸载应用可删除已保存的设置与快照。")
                Text("你控制的分享").font(.title3.bold())
                Text("只有你主动选择分享报告后，报告文本才交给你选择的应用或服务。报告预览展示完整分享内容，包含设备类型、硬件型号、系统版本及当时指标，不包含设备唯一标识符。分享目标将按其自身政策处理数据。")
                Text("权限与网络").font(.title3.bold())
                Text("应用不申请定位、照片、联系人、麦克风或广告追踪权限。网络状态通过系统接口在本地读取，不向服务器发送探测请求。")
                Text("反馈").font(.title3.bold())
                Text("开发者：王成。隐私问题或数据处理相关咨询，请发送邮件至 remixjc@foxmail.com。你主动发送的邮件和附件由邮件服务提供商传送，仅用于处理你的咨询；请勿提供密码、验证码或其他敏感信息。")
                Link("联系开发者", destination: SupportLinks.email)
                Text("政策更新").font(.title3.bold())
                Text("应用功能或数据处理方式变化时，我们会更新隐私政策并注明生效日期。当前版本不收集、出售或共享用于追踪的个人数据。")
                Link("查看网页版隐私政策", destination: SupportLinks.privacy)
            }.padding(24).frame(maxWidth: 700, alignment: .leading)
                .textSelection(.enabled)
        }.navigationTitle("隐私政策").navigationBarTitleDisplayMode(.inline)
    }
}

private enum SupportLinks {
    static let email = URL(string: "mailto:remixjc@foxmail.com")!
    static let privacy = URL(string: "https://remixjc.github.io/ios_systemstatus/privacy.html")!
    static let support = URL(string: "https://remixjc.github.io/ios_systemstatus/support.html")!
}

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("使用帮助与技术支持").font(.largeTitle.bold())
                Text("一屏查看设备状态。无广告、无追踪、无需注册，所有监测数据在设备本地处理。")
                Text("如何查看指标来源？").font(.title3.bold())
                Text("点按任意指标卡片，在详情页查看当前读数与数据说明。")
                Text("为什么 CPU 或电量显示“—”？").font(.title3.bold())
                Text("第一次采样尚未形成差值、系统限制访问、模拟器不提供读数时，应用会显示不可用，不会生成模拟数值。")
                Text("网络累计与运营商账单为何不同？").font(.title3.bold())
                Text("累计值只覆盖应用前台、未暂停时相邻有效采样间的网络接口差值。它不记录后台流量、历史账期和运营商计费规则。")
                Text("如何节省电量？").font(.title3.bold())
                Text("在设置中将刷新间隔设为 2 秒，并关闭屏幕常亮。进入后台后采样自动停止。")
                Text("如何分享报告？").font(.title3.bold())
                Text("在设置中选择“预览并分享报告”，确认文本后使用系统分享按钮。存储容量不会写入报告。")
                Text("如何添加和设置桌面小组件？").font(.title3.bold())
                Text("长按主屏幕空白处，通过“编辑 → 添加小组件”搜索“系统状态”，选择小号、中号或大号。长按小组件并选择“编辑小组件”，可独立设置基础仪表盘或信息矩阵样式、指标和配色；选择“跟随 App 设置”时使用应用内默认值。")
                NavigationLink("设置与预览小组件") { WidgetSettingsView() }
                Text("为什么小组件不会每秒更新？").font(.title3.bold())
                Text("iOS 负责安排小组件刷新。电池、内存、存储和温度状态为该次刷新时的读数；CPU、网速、网络连接、亮度、音量与本次监测为 App 最近一次前台采样，并标注时间。超过 5 分钟的 App 快照显示“打开 App 更新”。")
                NavigationLink("隐私政策") { PrivacyView() }
                Text("联系开发者").font(.title3.bold())
                Text("开发者：王成\n支持邮箱：remixjc@foxmail.com")
                Link("通过邮件联系", destination: SupportLinks.email)
                Text("反馈时请说明应用版本、iOS 版本、设备型号、操作步骤和预期结果。截图或报告由你自行决定是否提供；发送前请检查并移除敏感信息。请勿发送密码或验证码。")
                Link("查看网页版帮助", destination: SupportLinks.support)
                Text("最后更新：2026 年 10 月 28 日").foregroundStyle(.secondary)
            }
            .padding(24).frame(maxWidth: 700, alignment: .leading)
            .textSelection(.enabled)
        }
        .navigationTitle("帮助与支持").navigationBarTitleDisplayMode(.inline)
    }
}
