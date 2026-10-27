import Foundation
import Darwin

final class SystemReader {
    private var previousCPU: [UInt64]?
    private let host = mach_host_self()
    deinit { mach_port_deallocate(mach_task_self_, host) }

    func resetCPU() { previousCPU = nil }

    func cpu() -> CPULoad? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        let ticks = [UInt64(info.cpu_ticks.0), UInt64(info.cpu_ticks.1),
                     UInt64(info.cpu_ticks.2), UInt64(info.cpu_ticks.3)]
        defer { previousCPU = ticks }
        guard let previousCPU else { return nil }
        // Natural-width wrapping subtraction avoids a rollover spike.
        let delta = zip(ticks, previousCPU).map { UInt64(UInt32(truncatingIfNeeded: $0) &- UInt32(truncatingIfNeeded: $1)) }
        let total = Double(delta.reduce(0, +))
        guard total > 0 else { return nil }
        return CPULoad(user: Double(delta[0] + delta[3]) / total * 100,
                       system: Double(delta[1]) / total * 100)
    }

    func memory() -> MemoryUsage? {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        var page: vm_size_t = 0
        guard host_page_size(host, &page) == KERN_SUCCESS else { return nil }
        let size = Double(page)
        return MemoryUsage(active: Double(info.active_count) * size,
                           inactive: Double(info.inactive_count) * size,
                           wired: Double(info.wire_count) * size,
                           compressed: Double(info.compressor_page_count) * size,
                           free: Double(info.free_count) * size)
    }

    func disk() -> DiskUsage? {
        guard let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
              let total = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity,
              total > 0 else { return nil }
        return DiskUsage(total: Double(total), available: min(Double(total), max(0, Double(available))))
    }

    func traffic() -> [String: TrafficCounters] {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0 else { return [:] }
        defer { freeifaddrs(addresses) }
        var result: [String: TrafficCounters] = [:]
        var current = addresses
        while let item = current {
            defer { current = item.pointee.ifa_next }
            let entry = item.pointee
            guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK),
                  let data = entry.ifa_data else { continue }
            let name = String(cString: entry.ifa_name)
            // Exclude loopback and VPN tunnels to avoid counting the same packet twice.
            guard name.hasPrefix("en") || name.hasPrefix("pdp_ip") else { continue }
            let counters = data.assumingMemoryBound(to: if_data.self).pointee
            result[name] = TrafficCounters(received: UInt64(counters.ifi_ibytes), sent: UInt64(counters.ifi_obytes))
        }
        return result
    }

    static var hardwareIdentifier: String {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        var value = utsname()
        uname(&value)
        let capacity = MemoryLayout.size(ofValue: value.machine)
        return withUnsafePointer(to: &value.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: capacity) {
                String(cString: $0)
            }
        }
        #endif
    }
}
