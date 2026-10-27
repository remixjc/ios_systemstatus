import XCTest
@testable import SystemStatus

final class MetricsTests: XCTestCase {
    func testNetworkSamplingUsesActualElapsedTime() {
        var sampler = TrafficSampler()
        let initial = sampler.sample(["en0": .init(received: 100, sent: 20)], at: 10)
        XCTAssertEqual(initial.download, 0)
        let second = sampler.sample(["en0": .init(received: 1100, sent: 520)], at: 12)
        XCTAssertEqual(second.download, 500)
        XCTAssertEqual(second.upload, 250)
        XCTAssertEqual(second.received, 1000)
    }

    func testReconnectAndNewInterfacesDoNotCreateSpikes() {
        var sampler = TrafficSampler()
        _ = sampler.sample(["en0": .init(received: 5000, sent: 5000)], at: 1)
        let result = sampler.sample(["en0": .init(received: 10, sent: 20),
                                     "pdp_ip0": .init(received: 100_000, sent: 80_000)], at: 2)
        XCTAssertEqual(result.download, 0)
        XCTAssertEqual(result.upload, 0)
        sampler.reset()
        let resumed = sampler.sample(["en0": .init(received: 90_000, sent: 90_000)], at: 100)
        XCTAssertEqual(resumed.download, 0)
    }

    func testInvalidTimeDoesNotDivideByZero() {
        var sampler = TrafficSampler()
        _ = sampler.sample(["en0": .init(received: 0, sent: 0)], at: 3)
        XCTAssertEqual(sampler.sample(["en0": .init(received: 10, sent: 10)], at: 3).download, 0)
    }

    func testCapacityAndFormattingBounds() {
        XCTAssertEqual(DiskUsage(total: 100, available: 25).fraction, 0.75)
        XCTAssertEqual(MemoryUsage(active: 20, inactive: 30, wired: 10, compressed: 10, free: 30).fraction, 0.7)
        XCTAssertEqual(Format.percent(1.8), "100%")
        XCTAssertEqual(Format.percent(-0.1), "0%")
        XCTAssertEqual(Format.bytes(.nan), "—")
        XCTAssertEqual(Format.rate(1500), "1.5 KB/s")
        XCTAssertEqual(Format.duration(3661), "01:01:01")
    }

    @MainActor func testLocalReportExcludesDiskSpaceAndSensitiveIdentifiers() {
        let monitor = SystemMonitor()
        monitor.disk = DiskUsage(total: 987654321000, available: 123456789000)
        let report = monitor.report
        XCTAssertFalse(report.contains("987.7 GB"))
        XCTAssertFalse(report.contains("123.5 GB"))
        XCTAssertFalse(report.contains("IMEI"))
        XCTAssertTrue(report.contains("不包含在导出报告中"))
    }
}
