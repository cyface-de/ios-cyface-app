//
//  Preview_Mocks.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 07.10.25.
//
import Foundation
import DataCapturing
import UIKit

/**
 An authenticator that does not communicate with any server and only provides a fake authentication token.

 - Author: Klemens Muthmann
 */
class MockAuthenticator: Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        onSuccess("fake-token")
    }

    func authenticate() async throws -> String {
        return "test"
    }

    func delete() async throws {
        print("Deleting User")
    }

    func logout() async throws {
         print("Logout")
    }

    func callback(url: URL) {
        print("Called back")
    }
}

@Observable class MockCurrentMeasurementViewModel: CurrentMeasurementViewModel {
    var hasFix: UIImage = UIImage(systemName: "mappin.slash")!

    var distance: String = "0 km"

    var speed: String = "0 km/s"

    var duration: String = "0:00:00"

    var latitude: String = "0.0"

    var longitude: String = "0.0"

    var error: (any Error)? = nil


}
