/*
 * Copyright 2025-2026 Cyface GmbH
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

@MainActor
protocol MeasurementViewModel {
    // MARK: - Properties
    var isCurrentlyCapturing: Bool { get }
    var isPaused: Bool { get }
    var showError: Bool { get set }
    var error: Swift.Error? { get }
    var isInitialized: Bool { get }
    var finishedMeasurements: [MeasurementListEntryViewModel] { get set }
    var modalitySelectorVM: ModalitySelectorViewModel { get }

    // MARK: - Methods
    func start()

    func pause()

    func stop()

    func startSynchronization()

    func deleteMeasurements(at: IndexSet)

    func currentMeasurementViewModel() -> CurrentMeasurementViewModel

    func logout() async
}

@MainActor
@Observable class ProductionMeasurementViewModel {
    // MARK: - Properties
    var isCurrentlyCapturing = false
    var isPaused = false
    var showError = false
    var error: Swift.Error? = nil
    var isInitialized = false
    var finishedMeasurements = [MeasurementListEntryViewModel]()
    var modalitySelectorVM: ModalitySelectorViewModel

    private var currentMeasurement: DataCapturing.Measurement?
    private var currentMeasurementVM: ProductionCurrentMeasurementViewModel?
    private var locationUpdateSubscription: AnyCancellable?
    
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
    private var storage: CapturedDataStorage?
    private var sessionRegistry: SessionRegistry?
    private var uploadFactory: UploadFactory?
    private var urlSession: URLSession?
    private var authenticator: Authenticator?
    private let synchronizationMessagesBus = PassthroughSubject<UploadStatus, Never>()
    private var synchronizationMessagesProcessingHandle: AnyCancellable? = nil
    private var uploadStatusForwardingHandle: AnyCancellable? = nil
    private var config: Config?

    // MARK: - Initializers
    init(backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate) {
        modalitySelectorVM = ProductionModalitySelectorViewModel(selectedModality: Modalities.defaultSelection)
        do {
            // Persistence Properties
            let coreDataStack = try CoreDataStack()
            self.persistenceLayer = PersistenceLayer(coreDataStack)
            let sensorValueFileFactory = try DefaultSensorValueFileFactory()
            self.coreDataStack = coreDataStack
            self.storage = CapturedCoreDataStorage(coreDataStack, 10, sensorValueFileFactory)

            // Data Upload Properties
            let config = try Config.load()
            let authenticator = OAuthAuthenticator(
                issuer: try config.getIssuerUri(),
                redirectUri: try config.getRedirectUri(),
                apiEndpoint: try config.getApiEndpoint(),
                clientId: config.clientId,
                authStateKey: CyfaceApp.authStateKey
            )
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

            // Initialize everything
            Task {
                if let coreDataStack = self.coreDataStack {
                    debugPrint("Calling Setup")
                    try await coreDataStack.setup()
                    debugPrint("Called Setup")

                    // Load a previously paused measurement
                    if let pausedMeasurement = try storage?.pausedMeasurement(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer) { [weak self] databaseIdentifier in
                        self?.onFinishedMeasurement(databaseIdentifier)
                    } {
                        try persistenceLayer?.on(measurementIdentifiedBy: pausedMeasurement.1) { measurement in
                            let distance = persistenceLayer?.calculateCoveredDistance(measurement: measurement) ?? 0.0
                            let startTime = measurement.time ?? Date.now
                            let duration = persistenceLayer?.duration(measurement: measurement) ?? 0.0
                            let lastLocation = measurement.typedTracks().last?.typedLocations().last
                            let latitude = lastLocation?.lat ?? 0
                            let longitude = lastLocation?.lon ?? 0
                            self.currentMeasurementVM = ProductionCurrentMeasurementViewModel(
                                measurement: pausedMeasurement.0,
                                distance: distance,
                                startTime: startTime,
                                accumulatedDuration: duration,
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                        self.isPaused = true
                        self.currentMeasurement = pausedMeasurement.0
                        self.modalitySelectorVM.currentMeasurement = currentMeasurement
                        subscribeToEvents(from: pausedMeasurement.1)
                    }

                    // Load the list of previously finished measurements
                    self.finishedMeasurements.append(contentsOf: try coreDataStack.wrapInContextReturn { context in
                        let request = MeasurementMO.fetchRequest()
                        request.predicate = NSPredicate(format: "synchronizable = true || synchronized = true")

                        return try request.execute().map { measurementMO in
                            let state = switch (measurementMO.synchronizable, measurementMO.synchronized) {
                            case (true, false): SyncStatus.local
                            case (true, true): SyncStatus.synchronized // Was wrong: should be synchronized, not failed
                            case (false, false): SyncStatus.failed
                            case (false, true): SyncStatus.synchronized
                            }
                            /*
                             case synchronizing --> should only happen during a running synchronization
                             */


                            return MeasurementListEntryViewModel(
                                syncStatus: state,
                                distance: persistenceLayer?.calculateCoveredDistance(measurement: measurementMO) ?? 0.0,
                                id: measurementMO.unsignedIdentifier
                            )
                        }
                    })

                    self.config = config
                    self.sessionRegistry = sessionRegistry
                    self.uploadFactory = uploadFactory
                    self.urlSession = urlSession
                    self.authenticator = authenticator
                    
                    // Set up the synchronization message handler ONCE during initialization
                    setupSynchronizationMessageHandler()
                    
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
    private func onFinishedMeasurement(_ databaseIdentifier: UInt64) {
        os_log("Cleanup after measurement has finished", log: OSLog.measurement, type: .debug)
        self.isCurrentlyCapturing = false
        self.isPaused = false
        self.currentMeasurement = nil
        self.currentMeasurementVM = nil
        self.locationUpdateSubscription = nil

        do {
            let distance = try persistenceLayer?.on(measurementIdentifiedBy: databaseIdentifier) { measurement in
                persistenceLayer?.calculateCoveredDistance(measurement: measurement)
            }

            finishedMeasurements.append(MeasurementListEntryViewModel(distance: distance ?? 0.0, id: databaseIdentifier))
        } catch {
            self.error = error
            self.showError = true
        }

        self.storage?.unsubscribe()
    }

    private func findMeasurementInView(_ measurement: FinishedMeasurement) -> MeasurementListEntryViewModel? {
        finishedMeasurements.first(where: {$0.id == measurement.identifier})
    }
    
    /// Sets up the synchronization message handler that listens to upload status events.
    /// This should only be called ONCE during initialization.
    private func setupSynchronizationMessageHandler() {
        synchronizationMessagesProcessingHandle = synchronizationMessagesBus.sink { [weak self] uploadStatus in
            // TODO: Ideally the upload Status should contain the HTTP response status
            let measurementIdentifier = uploadStatus.upload.measurement.identifier
            guard let measurementViewModel = self?.findMeasurementInView(uploadStatus.upload.measurement) else {
                return debugPrint("No view model for measurement \(measurementIdentifier)")
            }
            switch uploadStatus.status {
            case .started:
                debugPrint("App received upload started!")
                measurementViewModel.synchronizationStarted()
            case .finishedSuccessfully:
                debugPrint("App received upload finished successfully!")
                do {
                    try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                        loadedMeasurement.synchronizable = false
                        loadedMeasurement.synchronized = true
                    }
                } catch {
                    self?.error = error
                    self?.showError = true
                }
                measurementViewModel.synchronizationFinishedSuccessfully()
            case .finishedUnsuccessfully:
                debugPrint("App received upload finished unsuccessfully!")
                do {
                    try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                        loadedMeasurement.synchronizable = true
                        loadedMeasurement.synchronized = false
                    }
                } catch {
                    self?.error = error
                    self?.showError = true
                }
                measurementViewModel.syncStatus = .local
            case .finishedWithError(cause: let error):
                debugPrint("App received upload finished with error. Caused by \(error.localizedDescription)")
                debugPrint("Error type: \(type(of: error))")
                debugPrint("Error details: \(error)")
                
                // Check if this is actually a successful upload with "no location data"
                // or the legacy missingLocation error from BackgroundPayloadStorage
                let isNoLocationError: Bool
                if case ServerConnectionError.noLocation = error {
                    isNoLocationError = true
                } else if case UploadProcessError.missingLocation = error {
                    // This was the bug! The error was thrown during file storage, not because of missing GPS data
                    isNoLocationError = true
                } else {
                    // Also check if error description contains "no location" or similar phrases
                    isNoLocationError = error.localizedDescription.lowercased().contains("no location") ||
                                       error.localizedDescription.lowercased().contains("nolocation") ||
                                       error.localizedDescription.lowercased().contains("missinglocation")
                }
                
                if isNoLocationError {
                    // Special case: "noLocation" error means measurement uploaded successfully but had no location data
                    // OR it was the old bug where upload.location was nil during file storage
                    // In both cases, mark as synchronized to prevent retrying
                    debugPrint("⚠️ Treating as successful upload (no location data case)")
                    do {
                        try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                            loadedMeasurement.synchronizable = false
                            loadedMeasurement.synchronized = true
                        }
                        measurementViewModel.synchronizationFinishedSuccessfully()
                    } catch {
                        self?.error = error
                        self?.showError = true
                    }
                } else {
                    // Real error - mark as failed but keep synchronizable to allow retry
                    debugPrint("❌ Real error - marking as failed")
                    do {
                        try self?.persistenceLayer?.update(measurement: uploadStatus.upload.measurement) { loadedMeasurement in
                            loadedMeasurement.synchronizable = true
                            loadedMeasurement.synchronized = false
                        }
                    } catch {
                        self?.error = error
                        self?.showError = true
                    }
                    measurementViewModel.synchronizationFailed(error)
                }
            }
            debugPrint("Upload for measurement \(measurementIdentifier) changed status to \(uploadStatus.status)")
        }
    }
}

// MARK: - MeasurementViewModel adoption
extension ProductionMeasurementViewModel: @MainActor MeasurementViewModel {

    // MARK: - Methods
    func start() {
        debugPrint("Start Data Capturing")
        do {
            // Call only resume, if already paused.
            if isPaused, let existingMeasurement = currentMeasurement {
                try existingMeasurement.resume()
            } else {
                // Neues Measurement erstellen
                let currentMeasurement = DataCapturing.MeasurementImpl(
                    sensorCapturer: sensorCapturer,
                    locationCapturer: locationCapturer
                )

                self.currentMeasurement = currentMeasurement

                // TODO: I need to call this here (before start()) so it can receive the start event. However is seems weird, that the return is not required. Is this some kind of antipattern?
                _ = currentMeasurementViewModel()
                self.modalitySelectorVM.currentMeasurement = currentMeasurement


                guard let measurementId = try storage?.subscribe(to: currentMeasurement, self._modalitySelectorVM.selectedModality.dbValue, {[weak self] databaseIdentifier in
                    self?.onFinishedMeasurement(databaseIdentifier)
                }) else {
                    throw CyfaceError.unableToSubscribeToUpdates
                }

                subscribeToEvents(from: measurementId)
                // Start new Measurement
                try currentMeasurement.start()
            }
            isCurrentlyCapturing = true
            isPaused = false
        } catch {
            self.error = error
            self.showError = true
        }
    }

    private func subscribeToEvents(from measurementIdentifiedBy: UInt64) {
        // Subscribe to location updates to calculate distance in real-time
        self.locationUpdateSubscription = currentMeasurement?.events
            .compactMap { message -> GeoLocation? in
                if case .capturedLocation(let location) = message {
                    return location
                }
                return nil
            }
            .sink { [weak self] location in
                guard let self = self,
                      let persistenceLayer = self.persistenceLayer else { return }

                do {
                    // Calculate and update the distance
                    let distance = try persistenceLayer.on(measurementIdentifiedBy: measurementIdentifiedBy) { measurement in
                        persistenceLayer.calculateCoveredDistance(measurement: measurement)
                    }

                    // Update the current measurement view model with the new distance
                    self.currentMeasurementVM?.updateDistance(distance)
                } catch {
                    os_log(.error, log: .measurement, "Failed to update distance: %{public}@", error.localizedDescription)
                }
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
            startSynchronization()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func startSynchronization() {
        do {
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
            
            // Forward upload status events from the upload process to the synchronization message bus
            self.uploadStatusForwardingHandle = backgroundUploadProcess.uploadStatus.sink { [weak self] status in
                self?.synchronizationMessagesBus.send(status)
            }

            // Find and upload all synchronizable measurements
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

    func deleteMeasurements(at offsets: IndexSet) {
        do {
            for index in offsets {
                let measurement = finishedMeasurements[index]
                try persistenceLayer?.delete(measurementIdentifiedBy: measurement.id)
            }
            finishedMeasurements.remove(atOffsets: offsets)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func currentMeasurementViewModel() -> CurrentMeasurementViewModel {
        if let currentMeasurement = self.currentMeasurement {
            // Reuse existing view model if available
            if let existingVM = currentMeasurementVM {
                return existingVM
            }
            
            // Create new view model and keep a reference
            let viewModel = ProductionCurrentMeasurementViewModel(measurement: currentMeasurement)
            self.currentMeasurementVM = viewModel
            return viewModel
        } else {
            fatalError("No current measurement!")
        }
    }

    func logout() async {
        do {
            try await authenticator?.logout()
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
