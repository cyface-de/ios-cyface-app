/*
 * Copyright 2022-2025 Cyface GmbH
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

import SwiftUI
import DataCapturing

/**
 The view displayed to the user to login to a Cyface Server

 - author: Klemens Muthmann
 */
struct AuthenticationView {
    let authenticator: Authenticator?
    @Bindable var viewModel: InitialViewModel

    @Environment(\.dismiss) var dismiss

    class Coordinator: LoginViewControllerDelegate {
        let viewModel: InitialViewModel

        init(initialViewModel viewModel: InitialViewModel) {
            self.viewModel = viewModel
        }

        func onLoggedIn() {
            viewModel.isAuthenticated = true
        }

        func onError(error: any Error) {
            viewModel.error = error
        }
    }
}

extension AuthenticationView: UIViewControllerRepresentable {
    // MARK: - Methods
    func makeUIViewController(context: Context) -> some LoginViewController {
        LoginViewController(authenticator: authenticator, delegate: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Nothing to do here, but required by the `UIViewControllerRepresentable` Protocol
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(initialViewModel: viewModel)
    }
}

#Preview {
    AuthenticationView(
        authenticator: MockAuthenticator(),
        viewModel: InitialViewModel(
            backgroundUrlSessionEventDelegate: MockAppDelegate()
        )
    )
}
