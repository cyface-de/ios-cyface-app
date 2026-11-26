//
//  cyfaceappUITests.swift
//  cyfaceappUITests
//
//  Created by Klemens Muthmann on 10.10.24.
//

import XCTest

final class cyfaceappUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// The imprint and the privacy policy must be reachable without logging in.
    @MainActor
    func testLegalInformationIsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()

        let legalInformationButton = app.buttons["de.cyface.app.button.legalinformation"]
        XCTAssertTrue(legalInformationButton.waitForExistence(timeout: 10))
        legalInformationButton.tap()

        XCTAssertTrue(app.navigationBars["Rechtliches"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Impressum"].exists)
        XCTAssertTrue(app.buttons["Datenschutzerklärung"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Legal Information"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
