import Foundation
import UIKit

enum WidgetMetric: String, Codable, CaseIterable, Identifiable {
    case battery, memory, storage, thermal, cpu, network, connection, brightness, audio, session
    var id: String { rawValue }
    var title: String {
        switch self {
        case .battery: "电池"
        case .memory: "内存"
        case .storage: "存储"
        case .thermal: "温度状态"
        case .cpu: "CPU"
        case .network: "网络下载"
        case .connection: "网络连接"
        case .brightness: "屏幕亮度"
        case .audio: "系统音量"
        case .session: "本次监测"
        }
    }
    var symbol: String {
        switch self {
        case .battery: "battery.75percent"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .thermal: "thermometer.medium"
        case .cpu: "cpu"
        case .network: "arrow.down.circle"
        case .connection: "antenna.radiowaves.left.and.right"
        case .brightness: "sun.max.fill"
        case .audio: "speaker.wave.2.fill"
        case .session: "timer"
        }
    }
    var usesAppSnapshot: Bool { [.cpu, .network, .connection, .brightness, .audio, .session].contains(self) }
}

enum WidgetStyle: String, Codable, CaseIterable, Identifiable {
    case standard, matrix
    var id: String { rawValue }
    var title: String { self == .standard ? "基础仪表盘" : "信息矩阵" }
}

enum WidgetAccent: String, Codable, CaseIterable, Identifiable {
    case blue, green, purple, orange
    var id: String { rawValue }
    var title: String {
        switch self {
        case .blue: "天空蓝"
        case .green: "薄荷绿"
        case .purple: "星空紫"
        case .orange: "活力橙"
        }
    }
}

struct WidgetPreferences: Codable, Equatable {
    var primary: WidgetMetric = .battery
    var second: WidgetMetric = .memory
    var third: WidgetMetric = .storage
    var fourth: WidgetMetric = .thermal
    var accent: WidgetAccent = .blue
    var showClock = true
    var style: WidgetStyle = .standard
    var metrics: [WidgetMetric] { [primary, second, third, fourth] }
}

extension WidgetPreferences {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        primary = try values.decodeIfPresent(WidgetMetric.self, forKey: .primary) ?? .battery
        second = try values.decodeIfPresent(WidgetMetric.self, forKey: .second) ?? .memory
        third = try values.decodeIfPresent(WidgetMetric.self, forKey: .third) ?? .storage
        fourth = try values.decodeIfPresent(WidgetMetric.self, forKey: .fourth) ?? .thermal
        accent = try values.decodeIfPresent(WidgetAccent.self, forKey: .accent) ?? .blue
        showClock = try values.decodeIfPresent(Bool.self, forKey: .showClock) ?? true
        style = try values.decodeIfPresent(WidgetStyle.self, forKey: .style) ?? .standard
    }
}

/// Only the listed foreground readings cross the App Group boundary.
/// Disk capacity is read by each process for display and is never persisted here.
struct WidgetAppSnapshot: Codable, Equatable {
    let date: Date
    let cpu: Double?
    let download: Double?
    let upload: Double?
    var connection: String?
    var brightness: Double?
    var volume: Double?
    var sessionDuration: TimeInterval?

    func isFresh(at date: Date) -> Bool {
        let age = date.timeIntervalSince(self.date)
        return age >= 0 && age < 300
    }
}

enum WidgetStore {
    static let groupID = "group.com.chengwang.systemstatus"
    static let kind = "SystemStatusDashboard"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }

    static func preferences(in defaults: UserDefaults? = nil) -> WidgetPreferences {
        decode(WidgetPreferences.self, key: "widget.preferences.v1", defaults: defaults) ?? .init()
    }

    @discardableResult
    static func save(_ value: WidgetPreferences, in defaults: UserDefaults? = nil) -> Bool {
        encode(value, key: "widget.preferences.v1", defaults: defaults)
    }

    static func snapshot(in defaults: UserDefaults? = nil) -> WidgetAppSnapshot? {
        decode(WidgetAppSnapshot.self, key: "widget.snapshot.v1", defaults: defaults)
    }

    @discardableResult
    static func save(_ value: WidgetAppSnapshot, in defaults: UserDefaults? = nil) -> Bool {
        encode(value, key: "widget.snapshot.v1", defaults: defaults)
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults?) -> T? {
        guard let data = (defaults ?? self.defaults)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, key: String, defaults: UserDefaults?) -> Bool {
        guard let defaults = defaults ?? self.defaults,
              let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}

struct WidgetReading {
    var date: Date
    var battery: Double?
    var charging: Bool
    var memory: MemoryUsage?
    var disk: DiskUsage?
    var thermal: String
    var lowPower: Bool
    var appSnapshot: WidgetAppSnapshot?
    var isSimulator: Bool

    @MainActor static func current() -> WidgetReading {
        let reader = SystemReader()
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let thermal: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = "正常"
        case .fair: thermal = "升温"
        case .serious: thermal = "较热"
        case .critical: thermal = "过热"
        @unknown default: thermal = "未知"
        }
        #if targetEnvironment(simulator)
        let simulator = true
        #else
        let simulator = false
        #endif
        return WidgetReading(date: Date(),
                             battery: device.batteryLevel < 0 ? nil : Double(device.batteryLevel),
                             charging: device.batteryState == .charging || device.batteryState == .full,
                             memory: reader.memory(), disk: reader.disk(), thermal: thermal,
                             lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
                             appSnapshot: WidgetStore.snapshot(), isSimulator: simulator)
    }

    static var placeholder: WidgetReading {
        WidgetReading(date: Date(), battery: 0.76, charging: false,
                      memory: MemoryUsage(active: 2e9, inactive: 1e9, wired: 1e9,
                                          compressed: 0.5e9, free: 3.5e9),
                      disk: DiskUsage(total: 256e9, available: 128e9),
                      thermal: "正常", lowPower: false, appSnapshot: nil, isSimulator: false)
    }

    func value(for metric: WidgetMetric, at date: Date) -> String {
        switch metric {
        case .battery: battery.map(Format.percent) ?? "—"
        case .memory: memory.map { Format.percent($0.fraction) } ?? "—"
        case .storage: disk.map { Format.percent($0.fraction) } ?? "—"
        case .thermal: thermal
        case .cpu:
            freshSnapshot(at: date)?.cpu.map { "\(Int($0.rounded()))%" } ?? "—"
        case .network:
            freshSnapshot(at: date)?.download.map(Format.rate) ?? "—"
        case .connection: freshSnapshot(at: date)?.connection ?? "—"
        case .brightness: freshSnapshot(at: date)?.brightness.map(Format.percent) ?? "—"
        case .audio: freshSnapshot(at: date)?.volume.map(Format.percent) ?? "—"
        case .session: freshSnapshot(at: date)?.sessionDuration.map(Format.duration) ?? "—"
        }
    }

    func fraction(for metric: WidgetMetric, at date: Date) -> Double? {
        switch metric {
        case .battery: battery
        case .memory: memory?.fraction
        case .storage: disk?.fraction
        case .cpu: freshSnapshot(at: date)?.cpu.map { min(1, max(0, $0 / 100)) }
        case .brightness: freshSnapshot(at: date)?.brightness
        case .audio: freshSnapshot(at: date)?.volume
        default: nil
        }
    }

    func detail(for metric: WidgetMetric, at date: Date) -> String {
        switch metric {
        case .battery: return battery == nil ? "系统未提供读数" : charging ? "正在充电" : lowPower ? "低电量模式" : "剩余电量"
        case .memory: return memory.map { "已用 \(Format.bytes($0.used))" } ?? "系统未提供读数"
        case .storage: return disk.map { "可用 \(Format.bytes($0.available))" } ?? "系统未提供读数"
        case .thermal: return lowPower ? "低电量模式开启" : "系统热状态"
        case .cpu, .network, .connection, .brightness, .audio, .session:
            guard let snapshot = freshSnapshot(at: date),
                  value(for: metric, at: date) != "—" else { return "打开 App 更新" }
            if metric == .session { return "App 前台快照" }
            return "App 快照 \(snapshot.date.formatted(date: .omitted, time: .shortened))"
        }
    }

    private func freshSnapshot(at date: Date) -> WidgetAppSnapshot? {
        guard let appSnapshot, appSnapshot.isFresh(at: date) else { return nil }
        return appSnapshot
    }
}
