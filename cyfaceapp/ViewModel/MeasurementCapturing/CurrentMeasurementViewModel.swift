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
import Combine

@MainActor
protocol CurrentMeasurementViewModel {
    var hasFix: String { get set }
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
@MainActor
@Observable class ProductionCurrentMeasurementViewModel: CurrentMeasurementViewModel {
    /// The GPS status image presented to the user. This changes based on whether the App has a GPS fix or not.
    var hasFix: String
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
    
    /// This keeps a handle to the Combine processing pipeline.
    ///
    /// If no such handle is kept, Swift will remove the pipeline stopping event handling in the process.
    private var measurementEventsSubscription: AnyCancellable?
    
    /// Timer for calculating the duration of the measurement
    private nonisolated(unsafe) var durationTimer: AnyCancellable?

    /// Start time of the current measurement segment
    private var startTime: Date?
    
    /// Accumulated duration from previous segments (in seconds)
    /// This is used to track total time when measurement is paused and resumed
    private var accumulatedDuration: TimeInterval = 0
    
    /// Formatter used to display the duration of the current measurement.
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }

    /// Initialize this view model with a measurement to observe.
    ///
    /// - Parameters:
    ///   - measurement: The measurement to observe for updates
    ///   - distance: Initial distance value
    ///   - speed: Initial speed value
    ///   - duration: Initial duration value
    ///   - latitude: Initial latitude value
    ///   - longitude: Initial longitude value
    init(measurement: DataCapturing.Measurement, distance: String = "0 m", speed: String = "0 km/h", duration: String = "00:00:00", latitude: String = "0.0", longitude: String = "0.0") {
        self.hasFix = "mappin.slash"
        self.distance = distance
        self.speed = speed
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude

        // Subscribe to measurement events from both sensor and location capturers
        self.measurementEventsSubscription = measurement.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                
                switch message {
                case .started(let timestamp):
                    self.startTime = timestamp
                    self.accumulatedDuration = 0 // Reset bei neuem Start
                    self.startDurationTimer()
                    
                case .resumed(let timestamp):
                    self.startTime = timestamp
                    // accumulatedDuration behalten - wird bei Pause aktualisiert
                    self.startDurationTimer()
                    
                case .paused:
                    // Akkumuliere die verstrichene Zeit vor dem Stoppen des Timers
                    if let startTime = self.startTime {
                        self.accumulatedDuration += Date().timeIntervalSince(startTime)
                    }
                    self.stopDurationTimer()
                    // Duration-Anzeige mit akkumulierter Zeit aktualisieren
                    if let formattedDuration = self.timeFormatter.string(from: self.accumulatedDuration) {
                        self.duration = formattedDuration
                    }
                    
                case .stopped:
                    self.stopDurationTimer()
                    // Bei Stop die finale Duration speichern
                    if let startTime = self.startTime {
                        self.accumulatedDuration += Date().timeIntervalSince(startTime)
                    }
                    if let formattedDuration = self.timeFormatter.string(from: self.accumulatedDuration) {
                        self.duration = formattedDuration
                    }
                    
                case .hasFix:
                    self.hasFix = "mappin"
                    
                case .fixLost:
                    self.hasFix = "mappin.slash"
                    
                case .capturedLocation(let location):
                    // Update speed (convert from m/s to km/h)
                    self.speed = String(format: "%.2f km/h", location.speed * 3.6)
                    self.latitude = String(format: "%.6f", location.latitude)
                    self.longitude = String(format: "%.6f", location.longitude)
                    
                default:
                    break
                }
            }
    }
    
    deinit {
        stopDurationTimer()
    }
    
    /// Start a timer to update the duration display
    private func startDurationTimer() {
        stopDurationTimer() // Clear any existing timer
        
        durationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDuration()
            }
    }
    
    /// Stop the duration timer
    private nonisolated func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }
    
    /// Update the duration display based on elapsed time
    private func updateDuration() {
        guard let startTime = startTime else { return }
        
        // Aktuelle Segment-Zeit + akkumulierte Zeit von vorherigen Segmenten
        let currentSegmentTime = Date().timeIntervalSince(startTime)
        let totalElapsedTime = accumulatedDuration + currentSegmentTime
        
        if let formattedDuration = timeFormatter.string(from: totalElapsedTime) {
            self.duration = formattedDuration
        }
    }
    
    /// Update the distance display
    ///
    /// This should be called from the measurement view model when distance changes
    /// - Parameter distanceInMeters: The distance in meters
    func updateDistance(_ distanceInMeters: Double) {
        self.distance = distanceInMeters < 1_000 
            ? String(format: "%.2f m", distanceInMeters) 
            : String(format: "%.2f km", distanceInMeters / 1_000)
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
