//
//  LoginViewControllerDelegate.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 07.10.25.
//

/**
 Protocol for an old style delegate for handling events reported by the AppAuth framework during authentication.

 - Author: Klemens Muthmann
 */
protocol LoginViewControllerDelegate {
    /// Handle a successful login.
    func onLoggedIn()
    /// Handle an error occuring during the login process.
    func onError(error: Error)
}
