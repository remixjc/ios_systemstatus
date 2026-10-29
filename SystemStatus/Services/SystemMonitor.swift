import SwiftUI
import Network
import AVFAudio
import Combine
import WidgetKit

@MainActor
final class SystemMonitor: ObservableObject {
    @Published var cpu: CPULoad?
    @Published var memory: MemoryUsage?
    @Published var disk: DiskUsage?
    @Published var download: Double = 0
    @Published var upload: Double = 0
    @Published var received: UInt64 = 0
    @Published var sent: UInt64 = 0
    @Published var cpuHistory: [HistoryPoint] = []
    @Published var networkHistory: [HistoryPoint] = []
    @Published var battery: Double?
    @Published var charging = "状态不可用"
    @Published var thermal = ProcessInfo.processInfo.thermalState
    @Published var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Published var brightness: Double = 0
    @Published var volume: Double = 0
    @Published var audioRoute = "系统音频输出"
    @Published var connection = "检测中"
    @Published var connected = false
    @Published var expensive = false
    @Published var constrained = false
    @Published var paused = false
    @Published var now = Date()
    @Published var interval: Double {
        didSet {
            UserDefaults.standard.set(interval, forKey: "refreshInterval")
            if active { schedule() }
        }
    }
    let startedAt = Date()
    let hardware = SystemReader.hardwareIdentifier
    private let reader = SystemReader()
    private let pathMonitor = NWPathMonitor()
    private var sampler = TrafficSampler()
    private var timer: Timer?
    private var active = false
    private var tick = 0
    private var lastScreen: UIScreen?
    private var hasTrafficBaseline = false
    private var lastWidgetWrite: Date?
    private var lastWidgetReload: Date?
    private(set) var widgetSnapshot: WidgetAppSnapshot?

    init() {
        let saved = UserDefaults.standard.double(forKey: "refreshInterval")
        interval = [0.5, 1, 2].contains(saved) ? saved : 1
        UIDevice.current.isBatteryMonitoringEnabled = true
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.connected = path.status == .satisfied
                self?.connection = path.status != .satisfied ? "未连接" :
                    path.usesInterfaceType(.wifi) ? "Wi-Fi" :
                    path.usesInterfaceType(.cellular) ? "蜂窝网络" :
                    path.usesInterfaceType(.wiredEthernet) ? "以太网" : "其他网络"
                self?.expensive = path.isExpensive
                self?.constrained = path.isConstrained
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "SystemStatus.NetworkPath"))
        sample()
    }

    func setActive(_ value: Bool) {
        guard active != value else { return }
        active = value
        if value {
            sampler.reset()
            hasTrafficBaseline = false
            reader.resetCPU()
            sample()
            schedule()
        } else {
            publishWidget(force: true)
            timer?.invalidate()
            timer = nil
            download = 0
            upload = 0
        }
    }

    func togglePause() {
        paused.toggle()
        sampler.reset()
        hasTrafficBaseline = false
        reader.resetCPU()
        download = 0
        upload = 0
        if !paused { sample() }
        publishWidget(force: true)
    }

    func clearHistory() {
        cpuHistory = []
        networkHistory = []
        received = 0
        sent = 0
        sampler.reset()
        hasTrafficBaseline = false
        widgetSnapshot = widgetSnapshot.map {
            WidgetAppSnapshot(date: $0.date, cpu: $0.cpu, download: nil, upload: nil,
                              connection: $0.connection, brightness: $0.brightness,
                              volume: $0.volume, sessionDuration: $0.sessionDuration)
        }
        publishWidget(force: true)
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.sample() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func sample() {
        now = Date()
        guard !paused else { return }
        cpu = reader.cpu()
        memory = reader.memory()
        if tick % 10 == 0 { disk = reader.disk() }
        tick += 1
        let rates = sampler.sample(reader.traffic(), at: now.timeIntervalSinceReferenceDate)
        download = rates.download
        upload = rates.upload
        received += rates.received
        sent += rates.sent
        if let cpu {
            cpuHistory.append(HistoryPoint(date: now, first: cpu.user, second: cpu.system))
        }
        networkHistory.append(HistoryPoint(date: now, first: download, second: upload))
        cpuHistory.removeAll { now.timeIntervalSince($0.date) > 60 }
        networkHistory.removeAll { now.timeIntervalSince($0.date) > 60 }
        let device = UIDevice.current
        battery = device.batteryLevel < 0 ? nil : Double(device.batteryLevel)
        switch device.batteryState {
        case .charging: charging = "正在充电"
        case .full: charging = "已充满"
        case .unplugged: charging = "未充电"
        default: charging = "状态不可用"
        }
        thermal = ProcessInfo.processInfo.thermalState
        lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        // Read the screen attached to this scene instead of assuming a fixed primary display.
        if let screen = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?.screen {
            lastScreen = screen
            brightness = Double(screen.brightness)
        }
        let audio = AVAudioSession.sharedInstance()
        volume = Double(audio.outputVolume)
        audioRoute = audio.currentRoute.outputs.map(\.portName).joined(separator: "、")
        if audioRoute.isEmpty { audioRoute = "系统音频输出" }
        widgetSnapshot = WidgetAppSnapshot(date: now, cpu: cpu?.total,
                                          download: hasTrafficBaseline ? download : nil,
                                          upload: hasTrafficBaseline ? upload : nil,
                                          connection: connection, brightness: brightness, volume: volume,
                                          sessionDuration: now.timeIntervalSince(startedAt))
        hasTrafficBaseline = true
        publishWidget()
    }

    private func publishWidget(force: Bool = false) {
        guard let widgetSnapshot else { return }
        let date = Date()
        if force || lastWidgetWrite.map({ date.timeIntervalSince($0) >= 15 }) ?? true {
            if WidgetStore.save(widgetSnapshot) { lastWidgetWrite = date }
        }
        if force || lastWidgetReload.map({ date.timeIntervalSince($0) >= 60 }) ?? true {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetStore.kind)
            lastWidgetReload = date
        }
    }

    var thermalText: String {
        switch thermal {
        case .nominal: "正常"
        case .fair: "略有升温"
        case .serious: "较热"
        case .critical: "过热"
        @unknown default: "未知"
        }
    }
    var screenDescription: String {
        guard let screen = lastScreen else { return "读取中" }
        return "\(Int(screen.nativeBounds.width)) × \(Int(screen.nativeBounds.height)) px · @\(Int(screen.scale))x"
    }

    /// Disk space is intentionally excluded: E174.1 only permits on-device display.
    var report: String {
        """
        系统状态 · 本地监测报告
        生成时间：\(now.formatted(date: .numeric, time: .standard))
        设备：\(UIDevice.current.model) · \(hardware)
        系统：\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        处理器：\(ProcessInfo.processInfo.processorCount) 核心
        CPU 用户：\(cpu.map { String(format: "%.1f%%", $0.user) } ?? "不可用")
        CPU 系统：\(cpu.map { String(format: "%.1f%%", $0.system) } ?? "不可用")
        物理内存：\(Format.bytes(Double(ProcessInfo.processInfo.physicalMemory)))
        网络连接：\(connection)
        下载：\(Format.rate(download))
        上传：\(Format.rate(upload))
        本次前台采样接收：\(Format.bytes(Double(received)))
        本次前台采样发送：\(Format.bytes(Double(sent)))
        电量：\(battery.map(Format.percent) ?? "不可用") · \(charging)
        温度状态：\(thermalText)
        低电量模式：\(lowPower ? "开启" : "关闭")

        数据说明：仅供参考。CPU、网络和虚拟内存为系统公开接口允许读取的快照；
        系统限制时不提供估算值。模拟器反映宿主环境，不能代表 iPhone 实际性能。
        存储空间仅在设备内显示，不包含在导出报告中。
        应用不会主动上传此报告；仅在你选择分享后交给所选目标。
        """
    }
}
