import XCTest

final class SystemStatusUITests: XCTestCase {
    @MainActor func testDashboardDetailsSettingsAndRotation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["dashboardClock"].waitForExistence(timeout: 10))
        let cpu = app.buttons["metric-cpu"]
        XCTAssertTrue(cpu.exists)
        cpu.tap()
        XCTAssertTrue(app.staticTexts["逻辑核心"].waitForExistence(timeout: 3))
        app.buttons["detailDone"].tap()
        app.buttons["pauseButton"].tap()
        XCTAssertTrue(app.buttons["继续采样"].exists)
        app.buttons["pauseButton"].tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.switches["24 小时制"].waitForExistence(timeout: 3))
        app.buttons["reportButton"].tap()
        XCTAssertTrue(app.navigationBars["监测报告"].waitForExistence(timeout: 3))
        app.buttons["关闭"].tap()
        app.buttons["settingsDone"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["metric-network"].waitForExistence(timeout: 3))
        let landscape = XCTAttachment(screenshot: app.screenshot())
        landscape.name = "Landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = .portrait
        let portrait = XCTAttachment(screenshot: app.screenshot())
        portrait.name = "Dashboard"
        portrait.lifetime = .keepAlways
        add(portrait)
    }
}
