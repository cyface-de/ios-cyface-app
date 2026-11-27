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

extension XCUIApplication {
    /**
     Launch the Cyface app for a UI test.

     The app runs with its UI test dependencies (see `AppDependencies` in the app): a fake login, an empty in-memory database and no data upload.
     So it needs no server, and every launch starts from the same state.

     - Parameters:
        - loggedIn: If `true` the app starts on the measurement screen, otherwise on the login screen.
        - language: The language of the app, `de` or `en`.
     - Returns: The launched app.
     */
    @MainActor
    static func launchCyface(loggedIn: Bool, language: String = "de") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UITest",
            "-UITestLoggedIn", loggedIn ? "YES" : "NO",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "de" ? "de_DE" : "en_US"
        ]
        app.launch()
        return app
    }

    /// Attach a screenshot of the app to the current test, so it is part of the test results.
    @MainActor
    func attachScreenshot(named name: String, to testCase: XCTestCase) {
        let attachment = XCTAttachment(screenshot: screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }
}
