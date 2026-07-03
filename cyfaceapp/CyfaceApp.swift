/*
 * Copyright 2022-2025 Cyface GmbH
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

import SwiftUI
import DataCapturing
import CoreMotion

@main
/// This is the entry point to the Cyface iOS application.
///
/// It starts the user interface and the backend as required simultaneously.
/// The backend is started via the ``appState``.
/// For further details see the documentation of the ``ApplicationState`` class.
/// The main UI is started via the Swift UI view ``ApplicationUI``.
/// That view is a kind of meta view, which decides, depending on the current `appState`, which view to show initially.
///
/// - author: Klemens Muthmann
struct CyfaceApp: App {
    /// The UIKit Application Delegate required for functionality not yet ported to SwiftUI.
    /// Especially reacting to backround network requests needs to be handled here.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// Key to store the current auth state, so each view may access and recreate the current auth state.
    static let authStateKey = "de.cyface.app.authstate"
    /// Display the initial user interface
    var body: some Scene {
        WindowGroup {
            InitialView(
                viewModel: InitialViewModel(
                    backgroundUrlSessionEventDelegate: appDelegate
                )
            )
                .tint(Color("Cyface-Green"))
        }
    }
}
