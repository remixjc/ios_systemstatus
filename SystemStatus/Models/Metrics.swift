import Foundation

struct CPULoad: Equatable {
    var user: Double
    var system: Double
    var total: Double { min(100, max(0, user + system)) }
}

struct MemoryUsage {
    let active: Double
    let inactive: Double
    let wired: Double
    let compressed: Double
    let free: Double
    var total: Double { active + inactive + wired + compressed + free }
    var used: Double { max(0, total - free) }
    var fraction: Double { total > 0 ? min(1, used / total) : 0 }
}

struct DiskUsage {
    let total: Double
    let available: Double
    var used: Double { max(0, total - available) }
    var fraction: Double { total > 0 ? min(1, used / total) : 0 }
}

struct TrafficCounters: Equatable {
    var received: UInt64 = 0
    var sent: UInt64 = 0
}

/// Rates use per-interface deltas so a newly attached interface cannot create a spike.
struct TrafficSampler {
    private var previous: [String: TrafficCounters] = [:]
    private var previousTime: TimeInterval?

    mutating func reset() {
        previous = [:]
        previousTime = nil
    }

    mutating func sample(_ current: [String: TrafficCounters], at time: TimeInterval)
        -> (download: Double, upload: Double, received: UInt64, sent: UInt64) {
        defer { previous = current; previousTime = time }
        guard let previousTime, time > previousTime else { return (0, 0, 0, 0) }
        let elapsed = time - previousTime
        var received: UInt64 = 0
        var sent: UInt64 = 0
        for (name, value) in current {
            guard let old = previous[name] else { continue }
            // Interface counters may reset after reconnecting.
            received += value.received >= old.received ? value.received - old.received : 0
            sent += value.sent >= old.sent ? value.sent - old.sent : 0
        }
        return (Double(received) / elapsed, Double(sent) / elapsed, received, sent)
    }
}

struct HistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let first: Double
    let second: Double
}

enum Metric: String, Identifiable, CaseIterable {
    case cpu, network, memory, storage, battery, thermal, session, brightness, audio, device
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: "CPU"
        case .network: "网络"
        case .memory: "内存"
        case .storage: "存储"
        case .battery: "电池"
        case .thermal: "温度状态"
        case .session: "本次监测"
        case .brightness: "亮度"
        case .audio: "音量"
        case .device: "设备"
        }
    }
}

enum Format {
    static func bytes(_ value: Double) -> String {
        guard value.isFinite, value >= 0 else { return "—" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var amount = value
        var index = 0
        while amount >= 1_000 && index < units.count - 1 { amount /= 1_000; index += 1 }
        return String(format: index == 0 ? "%.0f %@" : "%.1f %@", amount, units[index])
    }
    static func rate(_ value: Double) -> String { bytes(value) + "/s" }
    static func percent(_ fraction: Double) -> String {
        guard fraction.isFinite else { return "—" }
        return "\(Int((min(1, max(0, fraction)) * 100).rounded()))%"
    }
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = Int(max(0, interval))
        if seconds >= 3600 {
            return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
