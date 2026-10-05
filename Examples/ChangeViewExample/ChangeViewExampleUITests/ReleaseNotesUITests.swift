import XCTest

final class ReleaseNotesUITests: XCTestCase {
    @MainActor
    func testSheetFilteringDismissalAndEmbeddedChangelog() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-state"]
        app.launch()
        XCTAssertTrue(app.navigationBars["What’s New"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Version 1.1"].exists)
        XCTAssertFalse(app.staticTexts["Version 1.2"].exists)
        XCTAssertFalse(app.staticTexts["Version 1.0"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Last seen: 1.1"].waitForExistence(timeout: 5))
        app.buttons["Changelog"].tap()
        XCTAssertTrue(app.navigationBars["Changelog"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Version 1.2"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["ChangeView Example"].waitForExistence(timeout: 5))
        app.buttons["Empty changelog"].tap()
        XCTAssertTrue(app.staticTexts["No release notes to show."].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        app.buttons["Invalid changelog"].tap()
        XCTAssertTrue(app.staticTexts["Release notes could not be loaded."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLargeTextAndDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-state", "--large-text", "--dark"]
        app.launch()
        XCTAssertTrue(app.navigationBars["What’s New"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Version 1.1"].exists)
        // The close button must remain reachable at an accessibility text size.
        XCTAssertTrue(app.buttons["Close"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "WhatsNew-dark-accessibility-text"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Last seen: 1.1"].waitForExistence(timeout: 5))
    }
}
