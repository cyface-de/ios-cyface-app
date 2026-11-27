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

extension XCTestCase {
    /// The labels of the buttons that grant a permission, in English and German, best option first.
    private static let allowButtonLabels = [
        "Allow While Using App", "Beim Verwenden der App erlauben",
        "Change to Always Allow", "In „Immer erlauben“ ändern",
        "Allow", "Erlauben",
        "OK"
    ]

    /**
     Grant the system permission dialogs (location, motion) that appear during the test.

     On a fresh simulator the app asks for these permissions. The dialogs belong to the system and use the language of the simulator, not of the app.
     XCTest calls the registered monitor when such a dialog blocks the next interaction with the app.
     Without it, XCTest's default handling may decline the permission.
     */
    @MainActor
    func allowSystemPermissions() {
        addUIInterruptionMonitor(withDescription: "System permission dialog") { alert in
            guard let label = Self.allowButtonLabels.first(where: { alert.buttons[$0].exists }) else {
                return false
            }
            alert.buttons[label].tap()
            return true
        }
    }
}
