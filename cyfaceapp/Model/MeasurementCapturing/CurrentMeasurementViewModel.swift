/*
 * Copyright 2022-2025 Cyface GmbH
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
import UIKit // Required for UIImage

protocol CurrentMeasurementViewModel {
    var hasFix: UIImage { get set }
    var distance: String { get set }
    var speed: String { get set }
    var duration: String { get set }
    var latitude: String { get set }
    var longitude: String { get set }
    var error: Error? { get set }
}

/**
 The view model for displaying detail information about the currently captured measurement.

 The measurement is loaded from the Cyface backend and used to refresh the attributes necessary to show all the relevant information.
 All the attributes are formatted properly.
 */
@Observable class ProductionCurrentMeasurementViewModel: CurrentMeasurementViewModel {
    /// The GPS status image presented to the user. This changes based on whether the App has a GPS fix or not.
    var hasFix: UIImage
    /// The currently driven distance under the current measurement.
    var distance: String
    /// The current speed as reported by the Cyface data capturing service.
    var speed: String
    /// The duration of the measurement.
    var duration: String
    /// The geographical latitude in degrees as a decimal number (not sexagesimal).
    var latitude: String
    /// The geographical longitude in degress as a decimal number (not sexagesimal).
    var longitude: String
    /// The last error, that occured during capturing the current measurement.
    var error: (any Error)? = nil
    /// The CoreData stack used to access the database and load information about the current measurement.
    // TODO: private let coreDateStack: CoreDataManager
    /// The device wide unique identifier of the currently captured measurement.
    // TODO: private let measurementIdentifier: Int64?

    /// Initialize this view model with all zero values and an initialized ``ApplicationState``.
    init(measurement: DataCapturing.Measurement, distance: String = "0 m", speed: String = "0 km/s", duration: String = "0 s", latitude: String = "0", longitude: String = "0") {
        self.hasFix = UIImage(systemName: "mappin.slash")!
        self.distance = distance
        self.speed = speed
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude
        // TODO: self.coreDateStack = appState.dcs.coreDataStack
        // TODO: self.measurementIdentifier = appState.dcs.currentMeasurement
        // TODO: appState.dcs.handler.append(self.handle)
    }

    

}

/* TODO: extension CurrentMeasurementViewModel: CyfaceEventHandler {

    /// Formatter used to display the duration of the current measurement.
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }

    /// The handler for Cyface `DataCapturingEvent` instances.
    ///
    /// This updates the current measurement view on each new geographical location.
    /// It also refreshes the geographical location fix display.
    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
            case .geoLocationFixAcquired:
                if let hasFix = UIImage(named: "gps-available") {
                    DispatchQueue.main.async {
                        self.hasFix = hasFix
                    }
                }
            case .geoLocationFixLost:
                if let hasFix = UIImage(named: "gps-not-available") {
                    DispatchQueue.main.async {
                        self.hasFix = hasFix
                    }
                }
            case .geoLocationAcquired(position: let location):
                let persistenceLayer = PersistenceLayer(onManager: coreDateStack)
                do {
                    if let measurementIdentifier = measurementIdentifier {
                        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
                        let distanceInMeters = measurement.trackLength

                        if let formattedDuration = timeFormatter.string(from: abs(location.timestamp.timeIntervalSince(Date(timeIntervalSince1970: Double(measurement.timestamp) / 1_000.0)))) {
                            DispatchQueue.main.async {
                                self.duration = formattedDuration
                            }
                        }

                        DispatchQueue.main.async {
                            self.speed = String(format: "%.2f km/s", location.speed / 3.6)
                            self.latitude = String(format: "%.2f", location.latitude)
                            self.longitude = String(format: "%.2f", location.longitude)

                            self.distance = distanceInMeters < 1_000 ? String(format: "%.2f m", distanceInMeters) : String(format: "%.2f km", distanceInMeters / 1_000)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.errorMessage = error.localizedDescription
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }

}*/
