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
import Foundation
import CoreLocation
import DataCapturing

protocol MeasurementViewModel {
    // MARK: - Properties
    var isCurrentlyCapturing: Bool { get }
    var isPaused: Bool { get }
    var showError: Bool { get set }
    var error: Swift.Error? { get }

    // MARK: - Methods
    func start()

    func pause()

    func stop()

    func currentMeasurementViewModel() -> CurrentMeasurementViewModel
}

@MainActor
@Observable class ProductionMeasurementViewModel {
    // TODO: Initialise correctly if measurement has been running in the background
    // MARK: - Properties
    var isCurrentlyCapturing = false
    var isPaused = false
    var showError = false
    var error: Swift.Error? = nil

    private var currentMeasurement: DataCapturing.Measurement?
    private var sensorCapturer = SmartphoneSensorCapturer()
    private var locationCapturer = SmartphoneLocationCapturer(locationManagerFactory: {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        manager.distanceFilter = kCLDistanceFilterNone

        if manager.authorizationStatus == .denied || manager.authorizationStatus == .notDetermined || manager.authorizationStatus == .restricted {
            manager.requestWhenInUseAuthorization()
            manager.requestAlwaysAuthorization()
        }

        return manager
    })
}

// MARK: - MeasurementViewModel adoption
extension ProductionMeasurementViewModel: MeasurementViewModel {

    // MARK: - Methods
    func start() {
        debugPrint("Start Data Capturing")
        currentMeasurement = DataCapturing.MeasurementImpl(
            sensorCapturer: sensorCapturer,
            locationCapturer: locationCapturer
        )
        do {
            if isPaused {
                try currentMeasurement?.resume()
            } else {
                try currentMeasurement?.start()
            }
            isCurrentlyCapturing = true
            isPaused = false
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    func pause() {
        debugPrint("Pause Data Capturing")
        do {
            try currentMeasurement?.pause()
        } catch {
            self.error = error
            self.showError = true
        }

        isCurrentlyCapturing = false
        isPaused = true
    }
    
    func stop() {
        debugPrint("Stop Data Capturing")
        do {
            try currentMeasurement?.stop()
        } catch {
            self.error = error
            self.showError = true
        }
        isCurrentlyCapturing = false
        isPaused = false
    }
    
    func currentMeasurementViewModel() -> CurrentMeasurementViewModel {
        if let currentMeasurement = self.currentMeasurement {
            return ProductionCurrentMeasurementViewModel(measurement: currentMeasurement)
        } else {
            fatalError("No current measurement!")
        }
    }
}
