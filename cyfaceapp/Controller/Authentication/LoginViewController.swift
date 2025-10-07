//
//  LoginViewController.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 07.10.25.
//
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
    let authenticator: Authenticator

    // MARK: - Initializers
    init(authenticator: Authenticator, delegate: LoginViewControllerDelegate) {
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
