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
import Combine

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
    private var persistenceLayer: PersistenceLayer?
    private var coreDataStack: CoreDataStack?
    private var sessionRegistry: SessionRegistry?
    private var uploadFactory: UploadFactory?
    private var urlSession: URLSession?
    private var authenticator: Authenticator?
    private let synchronizationMessagesBus = PassthroughSubject<UploadStatus, Never>()
    private var synchronizationMessagesProcessingHandle: AnyCancellable? = nil
    private var config: Config?

    // MARK: - Initializers
    init(backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate) {
        do {
            let config = try Config.load()
            let authenticator = OAuthAuthenticator(
                issuer: try config.getIssuerUri(),
                redirectUri: try config.getRedirectUri(),
                apiEndpoint: try config.getApiEndpoint(),
                clientId: config.clientId,
                authStateKey: CyfaceApp.authStateKey
            )
            let coreDataStack = try CoreDataStack()
            self.persistenceLayer = PersistenceLayer(coreDataStack)
            let sensorValueFileFactory = try DefaultSensorValueFileFactory()
            self.coreDataStack = coreDataStack
            let uploadFactory = CoreDataBackedUploadFactory(dataStoreStack: coreDataStack)
            let sessionRegistry = PersistentSessionRegistry(dataStoreStack: coreDataStack, uploadFactory: uploadFactory)
            let backgroundEventHandler = BackgroundEventHandler(
                sessionRegistry: sessionRegistry,
                messageBus: synchronizationMessagesBus,
                authenticator: authenticator,
                collectorUrl: try config.getApiEndpoint()
            )

            let backgroundProcessDelegate = BackgroundProcessDelegate(
                dataStoreStack: coreDataStack,
                sensorValueFileFactory: sensorValueFileFactory,
                sessionRegistry: sessionRegistry,
                messageBus: synchronizationMessagesBus,
                eventHandler: backgroundEventHandler,
                backgroundUrlSessionEventDelegate: backgroundUrlSessionEventDelegate
            )

            let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: AppDelegate.discretionaryUploadSessionIdentifier)
            //Determines the maximum number of simulataneous connections to a Host. This is a per session property.
            urlSessionConfig.httpMaximumConnectionsPerHost = 1
            // This controles whether you are allowed to continue your upload/download over cellular access.
            urlSessionConfig.allowsCellularAccess = false
            // This makes sure you get an event on your app session launch (in your AppDelegate). (Your app might be killed by system even if your upload/download is going on)
            urlSessionConfig.sessionSendsLaunchEvents = true
            // This tells the system to wait for connectivity and then resume uploading/downloading. If the network goes away, it will restart from 0.
            // This is ignored by background sessions always waiting for connectivity
            urlSessionConfig.waitsForConnectivity = true
            // Only transmit during convenient times
            urlSessionConfig.isDiscretionary = true

            let urlSession = URLSession(configuration: urlSessionConfig, delegate: backgroundProcessDelegate, delegateQueue: nil)
            backgroundEventHandler.discretionaryUrlSession = urlSession

            Task {
                if let coreDataStack = self.coreDataStack {
                    debugPrint("Calling Setup")
                    try await coreDataStack.setup()
                    debugPrint("Called Setup")
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

                    self.config = config
                    self.sessionRegistry = sessionRegistry
                    self.uploadFactory = uploadFactory
                    self.urlSession = urlSession
                    self.authenticator = authenticator
                    isInitialized = true
                    startSynchronization()
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Private Methods
    /// Called if the measurement identified by the provided identifier has finished data capturing.
    private func onFinishedMeasurement(_ databaseIdentifier: UInt64) throws {
        os_log("Cleanup after measurement has finished", log: OSLog.measurement, type: .debug)
        self.isCurrentlyCapturing = false
        self.isPaused = false
        self.currentMeasurement = nil
        let distance = try persistenceLayer?.on(measurementIdentifiedBy: databaseIdentifier) { measurement in
            calculateCoveredDistance(tracks: measurement.typedTracks())
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

    private func findMeasurementInView(_ measurement: FinishedMeasurement) -> MeasurementListEntryViewModel? {
        finishedMeasurements.first(where: {$0.id == measurement.identifier})
    }
}

// MARK: - MeasurementViewModel adoption
extension ProductionMeasurementViewModel: @MainActor MeasurementViewModel {

    // MARK: - Methods
    func start() {
        debugPrint("Start Data Capturing")
        guard let coreDataStack = self.coreDataStack else {
            self.error = CyfaceError.notInitialized
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
        do {
            // TODO: Maybe try to setup everything here.
            guard let config = self.config else {
                throw CyfaceError.notInitialized
            }
            guard let sessionRegistry = self.sessionRegistry else {
                throw CyfaceError.notInitialized
            }
            guard let uploadFactory = self.uploadFactory else {
                throw CyfaceError.notInitialized
            }
            guard let authenticator = self.authenticator else {
                throw CyfaceError.notInitialized
            }
            guard let urlSession = self.urlSession else {
                throw CyfaceError.notInitialized
            }

        var backgroundUploadProcess = BackgroundUploadProcessBuilder.create(
            sessionRegistry: sessionRegistry,
            collectorUrl: try config.getUploadEndpoint(),
            uploadFactory: uploadFactory,
            authenticator: authenticator,
            urlSession: urlSession
        ).build()

            synchronizationMessagesProcessingHandle =  synchronizationMessagesBus.sink { [weak self] uploadStatus in
                // TODO: Ideally the upload Status should contain the HTTP response status
                let measurementIdentifier = uploadStatus.upload.measurement.identifier
                guard var measurementViewModel = self?.findMeasurementInView(uploadStatus.upload.measurement) else {
                    return debugPrint("No view model for measurement \(measurementIdentifier)")
                }
                switch uploadStatus.status {
                case .started:
                    measurementViewModel.synchronizing = true
                case .finishedSuccessfully:
                    do {
                        try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                            loadedMeasurement.synchronizable = false
                            loadedMeasurement.synchronized = true
                        }
                    } catch {
                        self?.error = error
                        self?.showError = true
                    }
                    measurementViewModel.synchronizing = false
                    measurementViewModel.synchronizationFailed = false
                case .finishedUnsuccessfully:
                    do {
                        try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                            loadedMeasurement.synchronizable = true
                            loadedMeasurement.synchronized = false
                        }
                    } catch {
                        self?.error = error
                        self?.showError = true
                    }
                    measurementViewModel.synchronizing = false
                    measurementViewModel.synchronizationFailed = false
                case .finishedWithError(cause: let error):
                    // TODO: Show the error somehow.
                    if case ServerConnectionError.noLocation = error {
                        do {
                            try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                                loadedMeasurement.synchronizable = false
                                loadedMeasurement.synchronized = true
                            }
                        } catch {
                            self?.error = error
                            self?.showError = true
                        }
                    } else {
                        do {
                            try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                                loadedMeasurement.synchronized = false
                                loadedMeasurement.synchronizable = false
                            }
                        } catch {
                            self?.error = error
                            self?.showError = true
                        }
                    }
                    measurementViewModel.synchronizing = false
                    measurementViewModel.synchronizationFailed = true
                }
                debugPrint("Upload for measurement \(measurementIdentifier) changed status to \(uploadStatus.status)")

            }

            try coreDataStack?.wrapInContext { context in
                let request = MeasurementMO.fetchRequest()
                request.predicate = NSPredicate(format: "synchronizable = true")

                try request.execute().map{ measurementMO in
                    try FinishedMeasurement(managedObject: measurementMO)
                }.forEach { finishedMeasurement in
                    debugPrint("Trying to upload measurement \(finishedMeasurement.identifier)")
                    Task {
                        try await backgroundUploadProcess.upload(measurement: finishedMeasurement)
                    }
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
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
