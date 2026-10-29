import XCTest

final class SystemStatusUITests: XCTestCase {
    @MainActor func testDeviceDetailsShowModelAndChip() {
        let app = XCUIApplication()
        app.launch()
        let device = app.buttons["metric-device"]
        XCTAssertTrue(device.waitForExistence(timeout: 5))
        device.tap()
        XCTAssertTrue(app.staticTexts["手机型号"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["芯片"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Device model and chip"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["detailDone"].tap()
        app.buttons["metric-audio"].tap()
        XCTAssertTrue(app.staticTexts["系统输出音量"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["音频路由"].exists)
        app.buttons["detailDone"].tap()
    }

    @MainActor func testWidgetSizesAndSavedSettings() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["settingsButton"].tap()
        let entry = app.buttons["widgetSettingsLink"]
        if !entry.isHittable { app.swipeUp() }
        entry.tap()
        XCTAssertTrue(app.navigationBars["桌面小组件"].waitForExistence(timeout: 5))
        app.buttons["widgetStylePicker"].tap()
        app.buttons["基础仪表盘"].tap()
        for size in ["小号", "中号", "大号"] {
            app.buttons[size].tap()
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Widget preview - \(size)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.buttons["widgetStylePicker"].tap()
        app.buttons["信息矩阵"].tap()
        for size in ["小号", "中号", "大号"] {
            app.buttons[size].tap()
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Matrix widget preview - \(size)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.buttons["小号"].tap()
        app.buttons["widgetMetric-主指标"].tap()
        app.buttons["存储"].tap()
        XCTAssertTrue(app.staticTexts["可用"].firstMatch.exists || app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH '可用 '")).firstMatch.exists)
        app.terminate()
        app.launch()
        app.buttons["settingsButton"].tap()
        if !app.buttons["widgetSettingsLink"].isHittable { app.swipeUp() }
        app.buttons["widgetSettingsLink"].tap()
        XCTAssertTrue(app.buttons["widgetMetric-主指标"].label.contains("存储"))
        XCTAssertTrue(app.buttons["widgetStylePicker"].label.contains("信息矩阵"))
        app.buttons["widgetMetric-主指标"].tap()
        app.buttons["电池"].tap()
    }

    @MainActor func testWidgetAppearsInHomeScreenGallery() {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let icon = springboard.icons["系统状态"].firstMatch
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        icon.press(forDuration: 1.2)
        for label in ["小型小组件", "中尺寸小组件", "大尺寸小组件"] {
            XCTAssertTrue(springboard.buttons[label].exists)
        }
        springboard.buttons["中尺寸小组件"].tap()
        XCUIDevice.shared.press(.home)
        let widget = springboard.icons.matching(NSPredicate(format: "label == %@ AND value CONTAINS %@", "系统状态", "小组件")).firstMatch
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        if !springboard.frame.contains(widget.frame) { springboard.swipeLeft() }
        XCTAssertTrue(springboard.frame.contains(widget.frame))
        let state = XCTAttachment(string: springboard.debugDescription)
        state.name = "Springboard installed widget"
        state.lifetime = .keepAlways
        add(state)
        let screenshot = XCTAttachment(screenshot: springboard.screenshot())
        screenshot.name = "Installed home widget"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

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
