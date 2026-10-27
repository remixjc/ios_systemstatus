import XCTest

final class SystemStatusUITests: XCTestCase {
    @MainActor private func assertAllMetricsVisible(_ app: XCUIApplication) {
        let viewport = app.frame
        for name in ["cpu", "network", "memory", "storage", "battery", "thermal",
                     "session", "brightness", "audio", "device"] {
            let card = app.buttons["metric-\(name)"]
            XCTAssertTrue(card.exists, "\(name) card must exist")
            XCTAssertTrue(card.isHittable, "\(name) card must be reachable without scrolling")
            XCTAssertTrue(viewport.insetBy(dx: -1, dy: -1).contains(card.frame),
                          "\(name) must fit on screen: \(card.frame), viewport: \(viewport)")
        }
        let footer = app.descendants(matching: .any)["dashboardFooter"].firstMatch
        XCTAssertTrue(footer.exists)
        XCTAssertTrue(viewport.contains(footer.frame), "The footer must also fit below the cards")
    }

    @MainActor func testAllMetricsFitOneScreen() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["metric-device"].waitForExistence(timeout: 10))
        assertAllMetricsVisible(app)
        let portrait = XCTAttachment(screenshot: app.screenshot())
        portrait.name = "All metrics - portrait"
        portrait.lifetime = .keepAlways
        add(portrait)
        XCUIDevice.shared.orientation = .landscapeLeft
        // Wait for the viewport to finish rotating before measuring card frames.
        let landscape = NSPredicate { _, _ in app.frame.width > app.frame.height }
        expectation(for: landscape, evaluatedWith: app)
        waitForExpectations(timeout: 5)
        assertAllMetricsVisible(app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "All metrics - landscape"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCUIDevice.shared.orientation = .portrait
    }

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
