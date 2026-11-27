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

/*
 Screen objects: each one knows how to find the elements of one screen of the app.
 Tests use them instead of raw queries, so a changed screen only needs a change here.
 Elements are found by their accessibility identifiers (`de.cyface.app.…`), so the tests work in every language.
 */

/// The login screen, shown if no user is logged in.
@MainActor
struct LoginScreen {
    let app: XCUIApplication

    var loginButton: XCUIElement { app.buttons["de.cyface.app.button.login"] }
    var legalInformationButton: XCUIElement { app.buttons["de.cyface.app.button.legalinformation"] }

    /// Wait until the login screen is shown and return whether it is.
    func waitUntilShown(timeout: TimeInterval = 10) -> Bool {
        loginButton.waitForExistence(timeout: timeout)
    }
}

/// The main screen with the list of measurements and the buttons to capture a new one.
@MainActor
struct MeasurementScreen {
    let app: XCUIApplication

    var startButton: XCUIElement { app.buttons["de.cyface.app.button.start"] }
    var pauseButton: XCUIElement { app.buttons["de.cyface.app.button.pause"] }
    var stopButton: XCUIElement { app.buttons["de.cyface.app.button.stop"] }
    var syncButton: XCUIElement { app.buttons["de.cyface.app.button.sync"] }
    var logoutButton: XCUIElement { app.buttons["de.cyface.app.button.logout"] }
    var legalInformationButton: XCUIElement { app.buttons["de.cyface.app.button.legalinformation"] }
    /// The details of the measurement currently captured. Only shown while capturing or paused.
    var currentMeasurement: XCUIElement { app.descendants(matching: .any)["de.cyface.app.view.currentmeasurement"] }
    /// The finished measurements in the list.
    var measurements: XCUIElementQuery { app.descendants(matching: .any)["de.cyface.app.list.measurements"].cells }

    /// Wait until the measurement screen is shown and return whether it is.
    func waitUntilShown(timeout: TimeInterval = 10) -> Bool {
        startButton.waitForExistence(timeout: timeout)
    }
}

/// The screen with the links to the imprint and the privacy policy.
@MainActor
struct LegalInformationScreen {
    let app: XCUIApplication

    /// Wait until the screen is shown and return whether it is. The title is German, since the tests run the app in German.
    func waitUntilShown(timeout: TimeInterval = 5) -> Bool {
        app.navigationBars["Rechtliches"].waitForExistence(timeout: timeout)
    }

    var imprintLink: XCUIElement { app.buttons["Impressum"] }
    var privacyPolicyLink: XCUIElement { app.buttons["Datenschutzerklärung"] }
}

/// Wait until the element is enabled or disabled, since SwiftUI updates the buttons asynchronously.
@MainActor
func waitUntil(_ element: XCUIElement, isEnabled: Bool, timeout: TimeInterval = 5) -> Bool {
    let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == %@", NSNumber(value: isEnabled)), object: element)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}

/// Wait until the query finds the expected number of elements.
@MainActor
func waitUntil(_ query: XCUIElementQuery, hasCount count: Int, timeout: TimeInterval = 10) -> Bool {
    let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %d", count), object: query)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}
