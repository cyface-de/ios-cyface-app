# View Model Architecture: Connecting MeasurementViewModel and CurrentMeasurementViewModel

## Overview

This document describes how the `MeasurementViewModel` and `CurrentMeasurementViewModel` are connected to maintain clear separation of concerns while enabling real-time updates from `SensorCapturer` and `LocationCapturer`.

## Architecture Principles

### Separation of Concerns

1. **MeasurementViewModel (Lifecycle Controller)**
   - Owns the `Measurement` instance
   - Controls measurement lifecycle (start, pause, stop)
   - Manages persistence and synchronization
   - Tracks finished measurements

2. **CurrentMeasurementViewModel (Display/Observer)**
   - Observes the `Measurement` via its `events` publisher
   - Updates UI-ready values (formatted strings)
   - Does NOT control measurement lifecycle
   - Calculates derived values (duration timer)

3. **Measurement (Data Aggregator)**
   - Merges publishers from `SensorCapturer` and `LocationCapturer`
   - Provides a single `events` publisher
   - Handles lifecycle state transitions

## Data Flow

```
┌─────────────────┐         ┌──────────────────┐
│ SensorCapturer  │────────▶│                  │
└─────────────────┘         │                  │
                            │   Measurement    │────┐
┌─────────────────┐         │                  │    │
│ LocationCapturer│────────▶│   (aggregator)   │    │
└─────────────────┘         │                  │    │
                            └──────────────────┘    │
                                                    │
                            ┌───────────────────────▼─────────────┐
                            │                                      │
                            │  CurrentMeasurementViewModel         │
                            │  (subscribes to events publisher)    │
                            │                                      │
                            └──────────────────────────────────────┘
                                           │
                            ┌──────────────▼───────────────┐
                            │                              │
                            │  MeasurementViewModel        │
                            │  (owns measurement lifecycle)│
                            │                              │
                            └──────────────────────────────┘
```

## Implementation Details

### CurrentMeasurementViewModel

**Responsibilities:**
- Subscribe to `Measurement.events` publisher
- Update real-time display values:
  - GPS fix status (`hasFix`)
  - Current speed
  - Geographic coordinates (latitude/longitude)
  - Duration (via timer)
  - Distance (via callback from MeasurementViewModel)

**Key Features:**
```swift
init(measurement: DataCapturing.Measurement) {
    // Subscribe to the merged events publisher
    self.measurementEventsSubscription = measurement.events
        .receive(on: DispatchQueue.main)
        .sink { [weak self] message in
            // Handle different message types
            switch message {
            case .hasFix: // Update GPS status
            case .fixLost: // Update GPS status
            case .capturedLocation(let location): // Update speed, coords
            case .started, .resumed: // Start duration timer
            case .paused, .stopped: // Stop duration timer
            // ...
            }
        }
}
```

**Duration Calculation:**
- Starts a timer on `.started` or `.resumed` events
- Updates duration display every second
- Stops timer on `.paused` or `.stopped` events

**Distance Updates:**
- Receives updates via `updateDistance(_ distanceInMeters: Double)` method
- Called by `MeasurementViewModel` when new locations are persisted
- Formats distance as meters or kilometers

### MeasurementViewModel

**Responsibilities:**
- Create and own the `Measurement` instance
- Control measurement lifecycle
- Maintain reference to `CurrentMeasurementViewModel`
- Calculate distance from persisted locations
- Update `CurrentMeasurementViewModel` with distance changes

**Key Features:**
```swift
func start() {
    let currentMeasurement = MeasurementImpl(
        sensorCapturer: sensorCapturer,
        locationCapturer: locationCapturer
    )
    
    // Subscribe to location updates for distance calculation
    locationUpdateSubscription = currentMeasurement.events
        .compactMap { message -> GeoLocation? in
            if case .capturedLocation(let location) = message {
                return location
            }
            return nil
        }
        .sink { [weak self] location in
            // Calculate distance from persisted data
            let distance = try persistenceLayer.on(measurementId) { measurement in
                self.calculateCoveredDistance(tracks: measurement.typedTracks())
            }
            
            // Update the current measurement view model
            self.currentMeasurementVM?.updateDistance(distance)
        }
}
```

**View Model Creation:**
```swift
func currentMeasurementViewModel() -> CurrentMeasurementViewModel {
    if let currentMeasurement = self.currentMeasurement {
        // Reuse existing view model if available
        if let existingVM = currentMeasurementVM {
            return existingVM
        }
        
        // Create and cache new view model
        let viewModel = ProductionCurrentMeasurementViewModel(measurement: currentMeasurement)
        self.currentMeasurementVM = viewModel
        return viewModel
    }
}
```

## Message Types

The `Message` enum (from DataCapturing framework) includes:

- `.started(timestamp)` - Measurement started
- `.stopped(timestamp)` - Measurement stopped
- `.paused(timestamp)` - Measurement paused
- `.resumed(timestamp)` - Measurement resumed
- `.hasFix` - GPS fix acquired
- `.fixLost` - GPS fix lost
- `.capturedLocation(GeoLocation)` - New location captured
- `.capturedSensor(SensorValue)` - New sensor value captured
- `.modalityChanged(to: String)` - Transportation mode changed

## Benefits of This Architecture

### ✅ Clear Separation of Concerns
- `MeasurementViewModel` controls lifecycle
- `CurrentMeasurementViewModel` only observes
- Neither view model directly touches capturers

### ✅ Reactive Updates
- Uses Combine publishers throughout
- Automatic propagation of updates
- No manual polling or refresh needed

### ✅ Testability
- Can mock `Measurement` protocol
- Can inject test publishers
- Each view model can be tested independently

### ✅ Memory Safety
- Uses `weak self` in closures
- Proper cleanup in `deinit`
- Cancellable subscriptions

### ✅ Thread Safety
- `.receive(on: DispatchQueue.main)` ensures UI updates on main thread
- `@MainActor` annotation on view models
- Lifecycle queue prevents race conditions

## Alternative Architectures Considered

### Option 2: Shared Publisher (More Decoupled)

Instead of passing the `Measurement` instance, you could:

```swift
// In MeasurementViewModel
private let measurementEventsPublisher = PassthroughSubject<Message, Never>()

func start() {
    let measurement = MeasurementImpl(...)
    measurement.events.sink { [weak self] message in
        self?.measurementEventsPublisher.send(message)
    }
}

// In CurrentMeasurementViewModel
init(eventsPublisher: AnyPublisher<Message, Never>) {
    self.subscription = eventsPublisher.sink { message in
        // Handle messages
    }
}
```

**Pros:**
- Even more decoupled
- `CurrentMeasurementViewModel` never sees `Measurement`

**Cons:**
- Extra indirection
- More boilerplate
- No clear benefit over current approach

### Option 3: Observation Protocol (More Traditional)

```swift
protocol MeasurementObserver {
    func didUpdateLocation(_ location: GeoLocation)
    func didAcquireFix()
    func didLoseFix()
}

// MeasurementViewModel would notify observers
```

**Pros:**
- More traditional delegate pattern

**Cons:**
- Less Swifty
- Doesn't leverage Combine
- More manual management

## Recommendation

The implemented solution (Option 1 with enhancements) is recommended because it:

1. **Uses Combine effectively** - Leverages the reactive nature of the data flow
2. **Maintains proper ownership** - `MeasurementViewModel` owns lifecycle
3. **Enables observation without control** - `CurrentMeasurementViewModel` can't accidentally affect lifecycle
4. **Integrates well with SwiftUI** - `@Observable` macro works seamlessly
5. **Handles real-time updates efficiently** - Direct subscription to merged publisher

## Testing Strategy

### Testing CurrentMeasurementViewModel

```swift
@Test func testLocationUpdateUpdatesSpeed() async {
    let publisher = PassthroughSubject<Message, Never>()
    let mockMeasurement = MockMeasurement(eventsPublisher: publisher.eraseToAnyPublisher())
    
    let viewModel = ProductionCurrentMeasurementViewModel(measurement: mockMeasurement)
    
    publisher.send(.capturedLocation(GeoLocation(
        latitude: 51.0,
        longitude: 13.0,
        accuracy: 5.0,
        speed: 10.0, // m/s
        time: Date(),
        altitude: 100.0,
        verticalAccuracy: 5.0
    )))
    
    #expect(viewModel.speed == "36.00 km/h") // 10 m/s = 36 km/h
}
```

### Testing MeasurementViewModel

```swift
@Test func testStartCreatesCurrentMeasurementViewModel() async {
    let viewModel = ProductionMeasurementViewModel(...)
    
    viewModel.start()
    
    let currentVM = viewModel.currentMeasurementViewModel()
    #expect(currentVM != nil)
}
```

## Future Enhancements

1. **Error Handling**
   - Propagate errors through the message stream
   - Add `.error(Error)` case to `Message` enum

2. **Performance Optimization**
   - Throttle high-frequency updates
   - Batch distance calculations

3. **Background Updates**
   - Handle app backgrounding/foregrounding
   - Reconnect subscriptions after app restart

4. **Advanced Metrics**
   - Calculate average speed
   - Track elevation gain/loss
   - Show battery impact

## Conclusion

This architecture successfully connects both view models while maintaining clear separation of concerns. The `Measurement` acts as a mediator, merging publishers from both capturers and providing a single stream of events that the `CurrentMeasurementViewModel` observes without controlling lifecycle.
