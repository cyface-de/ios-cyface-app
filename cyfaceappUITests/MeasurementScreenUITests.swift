/*
 * Copyright 2026 Cyface GmbH
 *
 * This file is part of the Cyface iOS App.
 *
 * The Cyface iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import XCTest
import CoreLocation

/// Tests of the measurement screen. The app starts logged in, with an empty database and without any server.
final class MeasurementScreenUITests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        // The measurement screen asks for the location permission.
        allowSystemPermissions()
    }

    /// A logged in user sees the empty measurement screen, on which only starting a measurement is possible.
    @MainActor
    func testInitialState() throws {
        let app = XCUIApplication.launchCyface(loggedIn: true)
        let screen = MeasurementScreen(app: app)

        XCTAssertTrue(screen.waitUntilShown())
        XCTAssertTrue(screen.startButton.isEnabled)
        XCTAssertFalse(screen.pauseButton.isEnabled)
        XCTAssertFalse(screen.stopButton.isEnabled)
        XCTAssertFalse(screen.currentMeasurement.exists)
        XCTAssertEqual(screen.measurements.count, 0)

        app.attachScreenshot(named: "Measurement Screen", to: self)
    }

    /// The imprint and the privacy policy are reachable from the measurement screen.
    @MainActor
    func testLegalInformationIsReachable() throws {
        let app = XCUIApplication.launchCyface(loggedIn: true)
        let screen = MeasurementScreen(app: app)
        XCTAssertTrue(screen.waitUntilShown())

        screen.legalInformationButton.tap()

        let legalInformation = LegalInformationScreen(app: app)
        XCTAssertTrue(legalInformation.waitUntilShown())
        XCTAssertTrue(legalInformation.imprintLink.exists)
        XCTAssertTrue(legalInformation.privacyPolicyLink.exists)
    }

    /// Capturing a measurement: start, pause, stop. Afterwards the measurement is in the list.
    @MainActor
    func testCaptureMeasurement() throws {
        // The simulator has no GPS. Give it a location in Dresden.
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 51.0504, longitude: 13.7373))
        let app = XCUIApplication.launchCyface(loggedIn: true)
        let screen = MeasurementScreen(app: app)
        XCTAssertTrue(screen.waitUntilShown())

        screen.startButton.tap()

        XCTAssertTrue(screen.currentMeasurement.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil(screen.startButton, isEnabled: false))
        XCTAssertTrue(screen.pauseButton.isEnabled)
        XCTAssertTrue(screen.stopButton.isEnabled)
        app.attachScreenshot(named: "Capturing", to: self)

        screen.pauseButton.tap()
        XCTAssertTrue(waitUntil(screen.startButton, isEnabled: true))
        XCTAssertFalse(screen.pauseButton.isEnabled)
        XCTAssertTrue(screen.stopButton.isEnabled)
        XCTAssertTrue(screen.currentMeasurement.exists)

        screen.stopButton.tap()
        XCTAssertTrue(waitUntil(screen.measurements, hasCount: 1))
        XCTAssertFalse(screen.currentMeasurement.exists)
        XCTAssertTrue(screen.startButton.isEnabled)
        XCTAssertFalse(screen.stopButton.isEnabled)
        app.attachScreenshot(named: "Finished Measurement", to: self)
    }

    /// Logging out returns to the login screen.
    @MainActor
    func testLogout() throws {
        let app = XCUIApplication.launchCyface(loggedIn: true)
        let screen = MeasurementScreen(app: app)
        XCTAssertTrue(screen.waitUntilShown())

        screen.logoutButton.tap()

        XCTAssertTrue(LoginScreen(app: app).waitUntilShown())
    }
}
