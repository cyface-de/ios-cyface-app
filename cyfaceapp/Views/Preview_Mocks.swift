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
import Foundation
import DataCapturing
import UIKit

class MockAppDelegate: BackgroundURLSessionEventDelegate {
    var completionHandler: (() -> Void)?
    
    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
}
/**
 An authenticator that does not communicate with any server and only provides a fake authentication token.
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

/// A mock view model for the view showing the main dialog of the application.
///
/// It is used for previews and UI testing.
/// This view model shows only static values and is otherwise quite dumb.
@MainActor 
@Observable class MockMeasurementViewModel: MeasurementViewModel {
    var isInitialized = true
    var finishedMeasurements = [MeasurementListEntryViewModel]()
    var isCurrentlyCapturing: Bool
    var isPaused: Bool
    var showError: Bool
    var error: Swift.Error?
    var isLoggedIn: Bool
    let modalitySelectorVM: any ModalitySelectorViewModel = MockModalitySelectorViewModel()

    init(
        isCurrentlyCapturing: Bool = false,
        isPaused: Bool = false,
        showError: Bool = false,
        error: Swift.Error? = nil,
        isLoggedIn: Bool = true
    ) {
        self.isCurrentlyCapturing = isCurrentlyCapturing
        self.isPaused = isPaused
        self.showError = showError
        self.error = error
        self.isLoggedIn = isLoggedIn
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
        finishedMeasurements.append(MeasurementListEntryViewModel(id: UInt64(finishedMeasurements.count)))
    }

    func startSynchronization() {
        debugPrint("Starting Synchronization")
    }

    func deleteMeasurements(at: IndexSet) {
        debugPrint("Deleting")
        finishedMeasurements.remove(atOffsets: at)
    }

    func currentMeasurementViewModel() -> any CurrentMeasurementViewModel {
        return MockCurrentMeasurementViewModel()
    }

    func logout() async {
        isLoggedIn = false
    }
}

@MainActor
@Observable
class MockModalitySelectorViewModel: ModalitySelectorViewModel {
    var selectedModality: Modalities = Modalities.defaultSelection

    var currentMeasurement: (any DataCapturing.Measurement)?
}
