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

import CoreData
import DataCapturing

/// An ``Authenticator`` that also knows whether a user is currently logged in.
protocol SessionAuthenticator: Authenticator {
    /// `true` if a user is logged in; `false` otherwise.
    var isLoggedIn: Bool { get }
}

extension OAuthAuthenticator: SessionAuthenticator {}

/**
 The dependencies the app uses to talk to the outside world, like the identity provider and the database.

 The app uses the ``production`` dependencies.
 In Debug builds, UI tests can replace them by launching the app with the `-UITest` argument (see ``fromLaunchArguments()``).
 The app then runs without a server and with an empty database, so the UI tests can reach every screen without a real login.
 */
struct AppDependencies {
    /// Creates the authenticator used to log in, log out and provide tokens for data uploads.
    let makeAuthenticator: (Config) throws -> SessionAuthenticator
    /// The CoreData store type, like `NSSQLiteStoreType` or `NSInMemoryStoreType`.
    let storeType: String
    /// Whether finished measurements are uploaded to the server.
    let synchronizationEnabled: Bool

    /// The dependencies of the app used in production: the OAuth identity provider and a persistent SQLite database.
    static let production = AppDependencies(
        makeAuthenticator: { config in
            OAuthAuthenticator(
                issuer: try config.getIssuerUri(),
                redirectUri: try config.getRedirectUri(),
                apiEndpoint: try config.getApiEndpoint(),
                clientId: config.clientId,
                authStateKey: CyfaceApp.authStateKey
            )
        },
        storeType: NSSQLiteStoreType,
        synchronizationEnabled: true
    )

    /**
     The dependencies selected by the launch arguments of the app.

     In Debug builds the argument `-UITest` selects the UI test dependencies. The user is logged in, unless `-UITestLoggedIn NO` is passed as well.
     Release builds always use the ``production`` dependencies.
     */
    static func fromLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        #if DEBUG
        if arguments.contains("-UITest") {
            // Launch arguments like `-UITestLoggedIn NO` end up in the argument domain of the user defaults.
            let defaults = UserDefaults.standard
            let loggedIn = defaults.object(forKey: "UITestLoggedIn") == nil || defaults.bool(forKey: "UITestLoggedIn")
            return .uiTest(loggedIn: loggedIn)
        }
        #endif
        return .production
    }
}

#if DEBUG
extension AppDependencies {
    /**
     The dependencies used by UI tests: a fake login, an in-memory database that is empty on every launch, and no data upload.

     - Parameter loggedIn: Whether the app starts with a logged in user.
     */
    static func uiTest(loggedIn: Bool) -> AppDependencies {
        // Login and logout must be shared by all view models, just like the stored auth state in production.
        let authenticator = UITestAuthenticator(isLoggedIn: loggedIn)
        return AppDependencies(
            makeAuthenticator: { _ in authenticator },
            storeType: NSInMemoryStoreType,
            synchronizationEnabled: false
        )
    }
}

/**
 An authenticator for UI tests, which logs in without an identity provider.
 */
final class UITestAuthenticator: SessionAuthenticator {
    private(set) var isLoggedIn: Bool

    init(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    func authenticate() async throws -> String {
        isLoggedIn = true
        return "ui-test-token"
    }

    func delete() async throws {
        isLoggedIn = false
    }

    func logout() async throws {
        isLoggedIn = false
    }

    func callback(url: URL) {
        // Nothing to do, since there is no external login page that calls back.
    }
}
#endif
