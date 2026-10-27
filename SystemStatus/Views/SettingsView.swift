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
                Section("隐私") {
                    NavigationLink("隐私政策") { PrivacyView() }
                    LabeledContent("广告与追踪", value: "无")
                    LabeledContent("数据上传", value: "无自动上传")
                    LabeledContent("第三方 SDK", value: "无")
                }
                Section {
                    LabeledContent("版本", value: "1.0.0 (1)")
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
                Text("生效日期：2026 年 10 月 27 日").foregroundStyle(.secondary)
                Text("系统状态在你的设备上读取和展示系统指标，不注册账号，不自动上传数据，不包含广告、分析或追踪 SDK。")
                Text("本地数据").font(.title3.bold())
                Text("刷新频率、时钟格式和常亮选项保存在应用本地。CPU、网络等最近 60 秒的曲线仅保存在内存中，退出进程后消失。存储容量仅在设备内展示，不包含在导出报告中。")
                Text("你控制的分享").font(.title3.bold())
                Text("只有你主动选择分享报告后，报告文本才交给你选择的应用或服务。报告预览展示完整分享内容，包含设备型号、系统版本及当时指标，不包含设备唯一标识符。分享目标将按其自身政策处理数据。")
                Text("权限与网络").font(.title3.bold())
                Text("应用不申请定位、照片、联系人、麦克风或广告追踪权限。网络状态通过系统接口在本地读取，不向服务器发送探测请求。卸载应用可删除已保存的设置。")
                Text("反馈").font(.title3.bold())
                Text("发布后可通过 App Store 产品页提供的支持渠道联系开发者。请勿在反馈中包含敏感信息。")
            }.padding(24).frame(maxWidth: 700, alignment: .leading)
        }.navigationTitle("隐私政策").navigationBarTitleDisplayMode(.inline)
    }
}
