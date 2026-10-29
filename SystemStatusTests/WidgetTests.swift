import XCTest
@testable import SystemStatus

final class WidgetTests: XCTestCase {
    func testSettingsAndSnapshotPersistIndependently() throws {
        let name = "SystemStatus.WidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        XCTAssertEqual(WidgetStore.preferences(in: defaults), WidgetPreferences())
        let settings = WidgetPreferences(primary: .cpu, second: .network, third: .battery,
                                         fourth: .storage, accent: .purple, showClock: false)
        let snapshot = WidgetAppSnapshot(date: Date(), cpu: 24, download: 1200, upload: 500)
        XCTAssertTrue(WidgetStore.save(settings, in: defaults))
        XCTAssertTrue(WidgetStore.save(snapshot, in: defaults))
        XCTAssertEqual(WidgetStore.preferences(in: defaults), settings)
        XCTAssertEqual(WidgetStore.snapshot(in: defaults), snapshot)
        let encoded = try JSONEncoder().encode(snapshot)
        let keys = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(Set(keys.keys), ["date", "cpu", "download", "upload"])
        defaults.set(Data("invalid".utf8), forKey: "widget.preferences.v1")
        XCTAssertEqual(WidgetStore.preferences(in: defaults), WidgetPreferences())
        XCTAssertEqual(WidgetStore.snapshot(in: defaults), snapshot)
    }

    func testAppSamplesExpireWithoutHidingDirectReadings() {
        let sampledAt = Date(timeIntervalSince1970: 1_000_000)
        var reading = WidgetReading.placeholder
        reading.appSnapshot = WidgetAppSnapshot(date: sampledAt, cpu: 24, download: 1500, upload: 500)
        XCTAssertEqual(reading.value(for: .cpu, at: sampledAt.addingTimeInterval(299)), "24%")
        XCTAssertEqual(reading.value(for: .network, at: sampledAt), "1.5 KB/s")
        let expired = sampledAt.addingTimeInterval(300)
        XCTAssertEqual(reading.value(for: .cpu, at: expired), "—")
        XCTAssertEqual(reading.value(for: .network, at: expired), "—")
        XCTAssertNil(reading.fraction(for: .cpu, at: expired))
        XCTAssertEqual(reading.detail(for: .network, at: expired), "打开 App 更新")
        XCTAssertEqual(reading.value(for: .battery, at: expired), "76%")
        XCTAssertEqual(reading.value(for: .cpu, at: sampledAt.addingTimeInterval(-1)), "—")
    }

    func testUnavailableSamplesNeverBecomeZeroReadings() {
        var reading = WidgetReading.placeholder
        reading.battery = nil
        reading.memory = nil
        reading.disk = nil
        reading.appSnapshot = WidgetAppSnapshot(date: reading.date, cpu: nil, download: nil, upload: nil)
        for metric in [WidgetMetric.battery, .memory, .storage, .cpu, .network] {
            XCTAssertEqual(reading.value(for: metric, at: reading.date), "—")
        }
        XCTAssertEqual(reading.detail(for: .cpu, at: reading.date), "打开 App 更新")
    }

    func testOldPreferencesKeepChoicesWhenStyleIsAdded() throws {
        let old = Data("""
        {"primary":"cpu","second":"network","third":"storage","fourth":"thermal","accent":"purple","showClock":false}
        """.utf8)
        let decoded = try JSONDecoder().decode(WidgetPreferences.self, from: old)
        XCTAssertEqual(decoded.primary, .cpu)
        XCTAssertEqual(decoded.accent, .purple)
        XCTAssertFalse(decoded.showClock)
        XCTAssertEqual(decoded.style, .standard)
    }

    func testMatrixSnapshotFieldsExpireTogether() {
        let date = Date()
        var reading = WidgetReading.placeholder
        reading.appSnapshot = WidgetAppSnapshot(date: date, cpu: 24, download: 1500, upload: 100,
                                               connection: "Wi-Fi", brightness: 0.25, volume: 0.6,
                                               sessionDuration: 3661)
        XCTAssertEqual(reading.value(for: .connection, at: date), "Wi-Fi")
        XCTAssertEqual(reading.value(for: .brightness, at: date), "25%")
        XCTAssertEqual(reading.value(for: .audio, at: date), "60%")
        XCTAssertEqual(reading.value(for: .session, at: date), "01:01:01")
        for metric in WidgetMetric.allCases.filter(\.usesAppSnapshot) {
            XCTAssertEqual(reading.value(for: metric, at: date.addingTimeInterval(300)), "—")
        }
    }
}
