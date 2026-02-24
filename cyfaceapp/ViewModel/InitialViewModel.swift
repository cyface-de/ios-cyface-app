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
import DataCapturing

/// The MVVM view model used during the initial startup of the application.
@Observable class InitialViewModel {
    /// A flag that is `false` as long as the user is not properly authenticated and `true` otherwise.
    var isAuthenticated = false
    /// A flag telling the UI whether the current error should be shown or not.
    var showError = false
    /// The most recent error encountered during initialization or `nil` if no error occurred.
    var error: Swift.Error?
    /// A flag that is `true` for as long as this application is in its initialization process and false otherwise.
    var isInitializing = false
    /// The authenticator used to associate the app with a Cyface user account.
    ///
    /// The account is used to store captured data and view analysis carried out on that data.
    var authenticator: Authenticator? = nil
    /// A delegate to handle resume of background URL Sessions.
    ///
    /// This is required to hand down to the main measurement view of the application.
    let backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate

    init(backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate) {
        self.backgroundUrlSessionEventDelegate = backgroundUrlSessionEventDelegate
        do {
            let config = try Config.load()

            let oAuthAuthenticator = OAuthAuthenticator(
                issuer: try config.getIssuerUri(),
                redirectUri: try config.getRedirectUri(),
                apiEndpoint: try config.getApiEndpoint(),
                clientId: config.clientId,
                authStateKey: CyfaceApp.authStateKey
            )
            self.isAuthenticated = oAuthAuthenticator.isLoggedIn
            self.authenticator = oAuthAuthenticator
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
