/*
 * Copyright 2025 Cyface GmbH
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
import Foundation

enum CyfaceError: Error {
    case notInitialized
    case noSuchMeasurement(identifier: UInt64)
    case invalidURL(url: String)
    case authenticatorNotInitialized
}

extension CyfaceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return NSLocalizedString("de.cyface.app.error.notinitialized", comment: "The view was not properly initialized, which is most likely caused if the persistence layer was not setup properly.")
        case .noSuchMeasurement:
            return NSLocalizedString("de.cyface.app.error.nosuchmeasurement", comment: "The app tried to load a measurement that did not exist!")
        case .invalidURL:
            return NSLocalizedString("de.cyface.app.error.invalidurl", comment: "An invalid URL was provided to the application.")
        case .authenticatorNotInitialized:
            return NSLocalizedString("de.cyface.app.error.authenticatornotinitialized", comment: "The authenticator was not initialized and thus authentication is not possible. This should not happen, if the app was properly implemented.")
        }
    }
}
