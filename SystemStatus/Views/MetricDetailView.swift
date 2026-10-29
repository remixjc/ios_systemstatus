import SwiftUI

struct MetricDetailView: View {
    let metric: Metric
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("当前读数") { readings }
                Section("数据说明") {
                    Text(explanation).font(.subheadline).foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle(metric.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.accessibilityIdentifier("detailDone")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label) {
            Text(value).monospacedDigit().multilineTextAlignment(.trailing).textSelection(.enabled)
        }
    }

    @ViewBuilder private var readings: some View {
        switch metric {
        case .cpu:
            row("芯片", monitor.device.chipName ?? "暂未收录")
            row("总使用率", monitor.cpu.map { String(format: "%.1f%%", $0.total) } ?? "暂不可用")
            row("用户", monitor.cpu.map { String(format: "%.1f%%", $0.user) } ?? "暂不可用")
            row("系统", monitor.cpu.map { String(format: "%.1f%%", $0.system) } ?? "暂不可用")
            row("逻辑核心", "\(ProcessInfo.processInfo.processorCount)")
            row("活跃核心", "\(ProcessInfo.processInfo.activeProcessorCount)")
            row("实时主频", "iOS 未提供公开接口")
        case .network:
            row("连接", monitor.connection)
            row("下载速率", Format.rate(monitor.download))
            row("上传速率", Format.rate(monitor.upload))
            row("本次接收", Format.bytes(Double(monitor.received)))
            row("本次发送", Format.bytes(Double(monitor.sent)))
            row("计费连接", monitor.expensive ? "是" : "否")
            row("低数据模式", monitor.constrained ? "开启" : "关闭")
        case .memory:
            row("物理内存", Format.bytes(Double(ProcessInfo.processInfo.physicalMemory)))
            row("活跃", monitor.memory.map { Format.bytes($0.active) } ?? "不可用")
            row("非活跃", monitor.memory.map { Format.bytes($0.inactive) } ?? "不可用")
            row("联动（Wired）", monitor.memory.map { Format.bytes($0.wired) } ?? "不可用")
            row("压缩", monitor.memory.map { Format.bytes($0.compressed) } ?? "不可用")
            row("空闲", monitor.memory.map { Format.bytes($0.free) } ?? "不可用")
            row("VM 统计合计", monitor.memory.map { Format.bytes($0.total) } ?? "不可用")
        case .storage:
            row("卷总容量", monitor.disk.map { Format.bytes($0.total) } ?? "不可用")
            row("已用", monitor.disk.map { Format.bytes($0.used) } ?? "不可用")
            row("可用", monitor.disk.map { Format.bytes($0.available) } ?? "不可用")
            row("使用率", monitor.disk.map { Format.percent($0.fraction) } ?? "不可用")
        case .battery:
            row("电量", monitor.battery.map(Format.percent) ?? "不可用")
            row("充电状态", monitor.charging)
            row("低电量模式", monitor.lowPower ? "开启" : "关闭")
        case .thermal:
            row("温度状态", monitor.thermalText)
            row("低电量模式", monitor.lowPower ? "开启" : "关闭")
        case .session:
            row("开始时间", monitor.startedAt.formatted(date: .abbreviated, time: .standard))
            row("本次打开时长", Format.duration(monitor.now.timeIntervalSince(monitor.startedAt)))
            row("采样状态", monitor.paused ? "已暂停" : "正在采样")
            row("采样间隔", "\(monitor.interval.formatted()) 秒")
        case .brightness:
            row("当前亮度", Format.percent(monitor.brightness))
            row("屏幕", monitor.screenDescription)
        case .audio:
            row("系统输出音量", monitor.volume.map(Format.percent) ?? "不可用")
            row("音频路由", monitor.audioRoute)
            if let error = monitor.audioError { row("读取状态", error) }
        case .device:
            row("手机型号", monitor.device.modelName)
            row("芯片", monitor.device.chipName ?? "暂未收录")
            row("硬件标识", monitor.hardware)
            row("系统版本", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
            row("物理内存", Format.bytes(Double(ProcessInfo.processInfo.physicalMemory)))
            row("处理器核心", "\(ProcessInfo.processInfo.processorCount)")
            row("当前屏幕", monitor.screenDescription)
            row("应用版本", "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"))")
        }
    }

    private var explanation: String {
        switch metric {
        case .cpu:
            "使用公开 Mach host_statistics 接口读取 CPU 时间片，按相邻采样差值计算使用率。用户值包含 nice 时间。第一次采样、系统不允许读取或没有新增时间片时显示不可用。iOS 不开放实时 CPU 主频，本应用不提供猜测值。模拟器中的数据可能反映 Mac 宿主机。"
        case .network:
            "读取 en 与 pdp_ip 网络接口的字节计数，按实际采样间隔计算速度；排除回环和 VPN 隧道以减少重复。累计值只记录应用在前台且未暂停时相邻有效采样的差值，清空曲线会同时清零累计值。接口重连或计数重置后重新建立基线。它不是本月流量、运营商账单或测速结果。连接状态不保证互联网可达。"
        case .memory:
            "使用公开 host_statistics64 接口读取虚拟内存页。占用比例为（统计合计 − 空闲）÷ 统计合计，并非内存压力或性能评分。压缩内存参与计算并显示在详情中。VM 统计合计与物理内存可能不同；非活跃内存可由系统回收，较高占用不代表故障。"
        case .storage:
            "显示应用所在数据卷的总容量和当前可用容量，每 10 次采样更新。容量使用十进制单位。APFS 共享空间、系统保留空间和可清理文件可能导致此处与“设置”不同。存储信息只在本机展示，不包含在分享报告中。"
        case .battery:
            "由 UIDevice 提供系统汇总电量与充电状态。双电池设备显示系统汇总值，不单独估算每块电池。模拟器通常不提供电池数据。电池健康度、循环次数、充电功率和剩余使用时长没有在此使用的公开读取接口。"
        case .thermal:
            "由 ProcessInfo.thermalState 提供正常、略有升温、较热和过热四档状态，不是摄氏温度。iOS 未向普通应用开放电芯和 CPU 温度读数。较热时建议减少高负载操作。"
        case .session:
            "显示本次应用进程启动后的经过时间，包含暂停和进入后台的时段。为了避免超出系统隐私接口的允许用途，不读取或显示设备开机时间。后台不持续采集数据，重新激活时建立新的 CPU 和网络采样基线。"
        case .brightness:
            "读取当前活动窗口所在屏幕的相对亮度，范围为 0–100%。此值不是实际亮度的尼特数，也不包含环境光和 HDR 带来的变化。展开、折叠和切换屏幕后会重新读取当前屏幕。"
        case .audio:
            "监听 AVAudioSession 输出音量变化；返回前台、切换耳机或中断结束时重新读取，暂停 CPU/网络采样不影响音量显示。前台使用可与其他应用音频混合的环境会话，不播放音频、不录音、不申请麦克风权限。显示的是媒体输出音量，不是铃声或通话音量。桌面小组件仍由 iOS 安排刷新。"
        case .device:
            "硬件标识来自系统公开接口，手机型号和芯片名称使用本地对照表展示；未收录的机型保留硬件标识，芯片显示暂未收录。模拟器展示模拟机型对应的名称，性能读数仍可能来自 Mac 宿主机。不采集序列号、IMEI、广告标识符或用户设置的设备名称。"
        }
    }
}
