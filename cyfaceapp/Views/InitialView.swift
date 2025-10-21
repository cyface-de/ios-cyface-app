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

import SwiftUI
import DataCapturing

/**
 The view shown when the app starts.

 This view decides which UI to show to the user.
 If the user is not authenticated it shows a way to authenticate, otherwise the user is directly forwarded to the main user interface..
 */
struct InitialView: View {
    @State var viewModel: InitialViewModel

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            if viewModel.isInitializing {
                SplashScreen()
            } else if viewModel.isAuthenticated {
                MeasurementView(viewModel: ProductionMeasurementViewModel(backgroundUrlSessionEventDelegate: viewModel.backgroundUrlSessionEventDelegate))
            } else {
                AuthenticationView(authenticator: viewModel.authenticator, viewModel: viewModel)
                    .onOpenURL(perform: { url in
                        viewModel.authenticator?.callback(url: url)
                    })
            }
        }
        .alert("Error", isPresented: $viewModel.showError, actions: {
            // actions
        }, message: {
            Text(viewModel.error?.localizedDescription ?? "")
        })
    }
}

#Preview {
    InitialView(
        viewModel: InitialViewModel(
            backgroundUrlSessionEventDelegate: MockAppDelegate()
        )
    )
        .tint(Color("Cyface-Green"))
}
