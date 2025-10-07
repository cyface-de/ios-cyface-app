//
//  initialViewModel.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 30.09.25.
//

import Foundation

@Observable class InitialViewModel {
    var isAuthenticated = false
    var hasAcceptedCurrentPrivacyPolicy = false
    var hasValidServerURL = false
    var error: Error?
}
