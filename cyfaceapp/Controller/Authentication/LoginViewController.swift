/*
 * Copyright 2025-2026 Cyface GmbH
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
import UIKit
import AppAuth
import DataCapturing
import OSLog

class LoginViewController: UIViewController {
    // MARK: - Properties
    /// A button shown on this view, to restart authentication if it fails.
    var authenticateButton: UIButton!
    /// The delegate to report success or errors from the login process, so the rest of the user interface can react to it.
    let delegate: LoginViewControllerDelegate
    /// The authenticator handling the authentication process.
    let authenticator: Authenticator?

    // MARK: - Initializers
    init(authenticator: Authenticator?, delegate: LoginViewControllerDelegate) {
        self.authenticator = authenticator
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        authenticateButton = UIButton(type: .system)
        let title = NSLocalizedString("loginButtonLable", comment: "The title of the button starting the login process.")
        authenticateButton.setTitle(title, for: .normal)
        authenticateButton.accessibilityIdentifier = "de.cyface.app.button.login"
        authenticateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(authenticateButton)

        authenticateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        authenticateButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        authenticateButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        authenticateButton.addTarget(self, action: #selector(doAuth), for: .touchUpInside)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let oauthAuthenticator = authenticator as? OAuthAuthenticator {
            oauthAuthenticator.callbackController = self
            os_log(.debug, log: OSLog.authorization, "Starting Authentication with Server %@", oauthAuthenticator.issuer.absoluteString)
        }
    }

    @objc func doAuth() {
        Task {
            guard let authenticator = self.authenticator else {
                return delegate.onError(error: CyfaceError.authenticatorNotInitialized)
            }
            do {
                // TODO: Why is this thrown away?
                _ = try await authenticator.authenticate()
                delegate.onLoggedIn()
            } catch {
                delegate.onError(error: error)
            }
        }
    }

}
