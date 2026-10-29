import AVFAudio
import XCTest
@testable import SystemStatus

final class AudioDeviceTests: XCTestCase {
    func testModelAndChipNamesIncludeRegionalIdentifiers() {
        for identifier in ["iPhone19,3", "iPhone19,7"] {
            let device = DeviceIdentity.resolve(identifier)
            XCTAssertEqual(device.modelName, "iPhone 18 Pro Max")
            XCTAssertEqual(device.chipName, "A20 Pro")
        }
        XCTAssertEqual(DeviceIdentity.resolve("iPhone19,2").modelName, "iPhone 18 Pro")
        XCTAssertEqual(DeviceIdentity.resolve("iPhone18,2").chipName, "A19 Pro")
        XCTAssertEqual(DeviceIdentity.resolve("iPhone17,1").modelName, "iPhone 16 Pro")
        XCTAssertEqual(DeviceIdentity.resolve("iPhone17,1").chipName, "A18 Pro")
        XCTAssertEqual(DeviceIdentity.resolve("iPad16,6").chipName, "M4")
        let unknown = DeviceIdentity.resolve("iPhone99,1", fallbackModel: "iPhone")
        XCTAssertTrue(unknown.modelName.contains("iPhone99,1"))
        XCTAssertNil(unknown.chipName)
    }

    @MainActor func testVolumeUpdatesWhileSamplingIsPausedAndAfterReturning() throws {
        let source = TestAudioOutput()
        let monitor = SystemMonitor(audioOutput: source)
        monitor.setActive(true)
        defer { monitor.setActive(false) }
        XCTAssertEqual(monitor.volume, 0.25)
        monitor.togglePause()
        let date = try XCTUnwrap(monitor.widgetSnapshot?.date)
        source.send(volume: 0.75, route: "耳机")
        XCTAssertEqual(monitor.volume, 0.75)
        XCTAssertEqual(monitor.audioRoute, "耳机")
        XCTAssertTrue(monitor.paused)
        XCTAssertEqual(monitor.widgetSnapshot?.volume, 0.75)
        XCTAssertEqual(monitor.widgetSnapshot?.date, date, "A volume event must not renew old CPU/network samples")
        monitor.setActive(false)
        XCTAssertEqual(source.stopCount, 1)
        // Late callbacks after backgrounding cannot mutate the displayed state.
        source.send(volume: 0.5, route: "扬声器")
        XCTAssertEqual(monitor.volume, 0.75)
        monitor.setActive(true)
        XCTAssertEqual(monitor.volume, 0.5)
        XCTAssertEqual(source.startCount, 2)
    }

    @MainActor func testUnavailableVolumeIsNotDisplayedAsAStalePercentage() {
        let source = TestAudioOutput()
        let monitor = SystemMonitor(audioOutput: source)
        monitor.setActive(true)
        defer { monitor.setActive(false) }
        source.onChange?(AudioOutputReading(volume: nil, route: "系统音频输出", error: "暂时中断"))
        XCTAssertNil(monitor.volume)
        XCTAssertNil(monitor.widgetSnapshot?.volume)
        XCTAssertEqual(monitor.audioError, "暂时中断")
        source.send(volume: 0.6, route: "扬声器")
        XCTAssertEqual(monitor.volume, 0.6)
        XCTAssertNil(monitor.audioError)
    }

    @MainActor func testForegroundAudioSessionCanMixWithOtherAudio() {
        let source = AudioOutputMonitor()
        var reading: AudioOutputReading?
        source.onChange = { reading = $0 }
        source.start()
        defer { source.stop() }
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
        XCTAssertNotNil(reading)
    }
}

@MainActor
private final class TestAudioOutput: AudioOutputSource {
    var onChange: ((AudioOutputReading) -> Void)?
    var startCount = 0
    var stopCount = 0
    private var reading = AudioOutputReading(volume: 0.25, route: "扬声器")
    func start() { startCount += 1; refresh() }
    func stop() { stopCount += 1 }
    func refresh() { onChange?(reading) }
    func send(volume: Double, route: String) {
        reading = AudioOutputReading(volume: volume, route: route)
        refresh()
    }
}
