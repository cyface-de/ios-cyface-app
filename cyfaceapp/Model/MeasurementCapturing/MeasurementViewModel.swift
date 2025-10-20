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
import OSLog

protocol MeasurementViewModel {
    // MARK: - Properties
    var isCurrentlyCapturing: Bool { get }
    var isPaused: Bool { get }
    var showError: Bool { get set }
    var error: Swift.Error? { get }
    var isInitialized: Bool { get }
    var finishedMeasurements: [MeasurementListEntryViewModel] { get set }

    // MARK: - Methods
    func start()

    func pause()

    func stop()

    func startSynchronization()

    func deleteMeasurements(at: IndexSet)

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
    var isInitialized = false
    var finishedMeasurements = [MeasurementListEntryViewModel]()

    private var currentMeasurement: DataCapturing.Measurement?
    private let sensorCapturer = SmartphoneSensorCapturer()
    private let locationCapturer = SmartphoneLocationCapturer(locationManagerFactory: {
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
    private var coreDataStack: CoreDataStack?

    // MARK: - Initializers
    init() {
        do {
            self.coreDataStack = try CoreDataStack()
            Task {
                if let coreDataStack = self.coreDataStack {
                    try await coreDataStack.setup()
                    self.finishedMeasurements.append(contentsOf: try coreDataStack.wrapInContextReturn { context in
                        let request = MeasurementMO.fetchRequest()
                        request.predicate = NSPredicate(format: "synchronizable = true || synchronized = true")

                        return try request.execute().map { measurementMO in
                            MeasurementListEntryViewModel(
                                synchronizationFailed: false,
                                synchronizing: false,
                                distance: calculateCoveredDistance(tracks: measurementMO.typedTracks()),
                                id: measurementMO.unsignedIdentifier
                            )
                        }
                    })
                    isInitialized = true
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Called if the measurement identified by the provided identifier has finished data capturing.
    private func onFinishedMeasurement(_ databaseIdentifier: UInt64) throws {
        os_log("Cleanup after measurement has finished", log: OSLog.measurement, type: .debug)
        self.isCurrentlyCapturing = false
        self.isPaused = false
        self.currentMeasurement = nil
        let distance = try coreDataStack?.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier = %@", NSNumber(value: databaseIdentifier))
            request.fetchLimit = 1

            guard let measurement = try request.execute().first else {
                throw MeasurementViewModelError.noSuchMeasurement(identifier: databaseIdentifier)
            }

            return calculateCoveredDistance(tracks: measurement.typedTracks())
        }
        finishedMeasurements.append(MeasurementListEntryViewModel(distance: distance ?? 0.0, id: databaseIdentifier))
    }

    private func calculateCoveredDistance(tracks: [TrackMO]) -> Double {
            return tracks
                .map { track in
                    var trackLength = 0.0
                    var prevLocation: GeoLocationMO? = nil
                    for location in track.typedLocations() {
                        if let prevLocation = prevLocation {
                            trackLength += location.distance(to: prevLocation)
                        }
                        prevLocation = location
                    }
                    return trackLength
                }
                .reduce(0.0) { accumulator, next in
                    accumulator + next
                }
    }
}

// MARK: - MeasurementViewModel adoption
extension ProductionMeasurementViewModel: @MainActor MeasurementViewModel {

    // MARK: - Methods
    func start() {
        debugPrint("Start Data Capturing")
        guard let coreDataStack = self.coreDataStack else {
            self.error = MeasurementViewModelError.notInitialized
            self.showError = true
            return
        }
        let currentMeasurement = DataCapturing.MeasurementImpl(
            sensorCapturer: sensorCapturer,
            locationCapturer: locationCapturer
        )
        self.currentMeasurement = currentMeasurement

        do {
            // TODO: Use this to recreate a measurement paused in the background during app start.
            let storage = CapturedCoreDataStorage(coreDataStack, 10, try DefaultSensorValueFileFactory())
            // TODO: Returns a measurementIdentifier. Do I need this for something?
            _ = try storage.subscribe(to: currentMeasurement, Modalities.bicycle.dbValue, {[weak self] databaseIdentifier in
                do {
                    try self?.onFinishedMeasurement(databaseIdentifier)
                } catch {
                    self?.error = error
                    self?.showError = true
                }
                storage.unsubscribe()
            })
            if isPaused {
                try currentMeasurement.resume()
            } else {
                try currentMeasurement.start()
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
    }

    func startSynchronization() {
        // TODO: Implement Synchronization
    }

    func deleteMeasurements(at: IndexSet) {
        // TODO: Implement Delete
    }

    func currentMeasurementViewModel() -> CurrentMeasurementViewModel {
        if let currentMeasurement = self.currentMeasurement {
            return ProductionCurrentMeasurementViewModel(measurement: currentMeasurement)
        } else {
            fatalError("No current measurement!")
        }
    }
}

enum MeasurementViewModelError: Error {
    case notInitialized
    case noSuchMeasurement(identifier: UInt64)
}

extension MeasurementViewModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return NSLocalizedString("de.cyface.app.error.notinitialized", comment: "The view was not properly initialized, which is most likely caused if the persistence layer was not setup properly.")
        case .noSuchMeasurement:
            return NSLocalizedString("de.cyface.app.error.nosuchmeasurement", comment: "The app tried to load a measurement that did not exist!")
        }
    }
}
