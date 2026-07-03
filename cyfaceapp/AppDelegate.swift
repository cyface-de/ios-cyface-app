/*
 * Copyright 2025 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import DataCapturing

/**
 Handles Application level UIKit events. This is still necessary for use cases that are not supported by SwiftUI yet or that need to be portable to older versions.
 */
class AppDelegate: NSObject, UIApplicationDelegate, BackgroundURLSessionEventDelegate {
    static let discretionaryUploadSessionIdentifier: String = "de.cyface.app"

    /// Called after waking up for handling a background `URLSession`.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        received(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }

    var completionHandler: (() -> Void)?

    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
}
