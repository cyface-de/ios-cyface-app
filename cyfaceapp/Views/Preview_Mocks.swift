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
    var hasFix = "mappin.slash"

    var distance: String = "0 km"

    var speed: String = "0 km/s"

    var duration: String = "0:00:00"

    var latitude: String = "0.0"

    var longitude: String = "0.0"

    var error: (any Error)? = nil
}

@Observable class MockMeasurementViewModel: MeasurementViewModel {
    var isCurrentlyCapturing: Bool
    var isPaused: Bool
    var showError: Bool
    var error: Swift.Error?

    init(isCurrentlyCapturing: Bool = false, isPaused: Bool = false, showError: Bool = false, error: Swift.Error? = nil) {
        self.isCurrentlyCapturing = isCurrentlyCapturing
        self.isPaused = isPaused
        self.showError = showError
        self.error = error
    }

    func start() {
        debugPrint("start")
        isCurrentlyCapturing = true
        isPaused = false
    }
    
    func pause() {
        debugPrint("pause")
        isCurrentlyCapturing = false
        isPaused = true
    }
    
    func stop() {
        debugPrint("stop")
        isCurrentlyCapturing = false
        isPaused = false
    }
    
    func currentMeasurementViewModel() -> any CurrentMeasurementViewModel {
        return MockCurrentMeasurementViewModel()
    }
    

}
