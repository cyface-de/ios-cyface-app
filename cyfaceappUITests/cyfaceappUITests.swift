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
        let app = XCUIApplication.launchCyface(loggedIn: false)
        let loginScreen = LoginScreen(app: app)
        XCTAssertTrue(loginScreen.waitUntilShown())

        loginScreen.legalInformationButton.tap()

        let legalInformation = LegalInformationScreen(app: app)
        XCTAssertTrue(legalInformation.waitUntilShown())
        XCTAssertTrue(legalInformation.imprintLink.exists)
        XCTAssertTrue(legalInformation.privacyPolicyLink.exists)
        app.attachScreenshot(named: "Legal Information", to: self)

        // The imprint must open inside the app, not in the Safari app.
        legalInformation.imprintLink.tap()
        sleep(10)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertFalse(app.navigationBars["Rechtliches"].isHittable)
        app.attachScreenshot(named: "Imprint", to: self)
    }

    /// Logging in leads to the measurement screen. The UI test login needs no identity provider.
    @MainActor
    func testLogin() throws {
        let app = XCUIApplication.launchCyface(loggedIn: false)
        let loginScreen = LoginScreen(app: app)
        XCTAssertTrue(loginScreen.waitUntilShown())

        loginScreen.loginButton.tap()

        XCTAssertTrue(MeasurementScreen(app: app).waitUntilShown())
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
