# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build (using Debug Development configuration)
xcodebuild -scheme "Cyface Development" -configuration "Debug Development" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" build

# Run all tests
xcodebuild -scheme "Cyface Development" -configuration "Debug Development" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" test

# Run a single test (unit)
xcodebuild -scheme "Cyface Development" -configuration "Debug Development" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" -only-testing "cyfaceappTests/cyfaceappTests/testName" test

# Run a single UI test
xcodebuild -scheme "Cyface Development" -configuration "Debug Development" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" -only-testing "cyfaceappUITests/cyfaceappUITests/testExample" test

# Build archive (Release)
xcodebuild -scheme "Cyface Production" -archivePath ./build/cyfaceapp.xcarchive -sdk iphoneos -configuration "Release Production" -destination generic/platform=iOS clean archive
```

Available schemes: `Cyface Development`, `Cyface Staging`, `Cyface Production`, `DataCapturing`

## Architecture

### MVVM + Combine + SwiftUI

The app uses MVVM with Swift's `@Observable` macro (SwiftUI 6.0+) and Combine for reactive data flow.

**Core view model split:**
- `MeasurementViewModel` (protocol) / `ProductionMeasurementViewModel` — owns measurement lifecycle (start/pause/stop), manages CoreData persistence, calculates distance, drives synchronization
- `CurrentMeasurementViewModel` (protocol) / `ProductionCurrentMeasurementViewModel` — subscribes to `Measurement.events` publisher, updates UI-ready display values (speed, coordinates, GPS fix, duration, distance)
- Mock variants (`MockMeasurementViewModel`, `MockCurrentMeasurementViewModel`) exist for SwiftUI previews and testing

**Data flow:**
```
SensorCapturer ──▶ Measurement (aggregator) ──▶ CurrentMeasurementViewModel ──▶ SwiftUI Views
LocationCapturer ──▶        │
                            └──▶ MeasurementViewModel (distance calc, lifecycle)
```

`Measurement.events` is a merged Combine publisher of `Message` enum values (`.started`, `.stopped`, `.paused`, `.resumed`, `.hasFix`, `.fixLost`, `.capturedLocation(GeoLocation)`, `.capturedSensor(SensorValue)`, `.modalityChanged(to:)`).

### Key Files
- `CyfaceApp.swift` — `@main` entry, injects `InitialViewModel` into SwiftUI environment
- `cyfaceapp/ViewModel/MeasurementCapturing/MeasurementViewModel.swift` — core lifecycle logic (~528 lines)
- `cyfaceapp/ViewModel/InitialViewModel.swift` — app startup, auth check, skips login if valid token exists
- `cyfaceapp/Model/PersistenceLayer.swift` — CoreData wrapper
- `cyfaceapp/Config.swift` — loads environment JSON from `Resources/`
- `cyfaceapp/CyfaceError.swift` — custom error types

### Multi-Environment Configuration
Three JSON configs in `cyfaceapp/Resources/`: `Development.json`, `Staging.json`, `Production.json`. `Config.swift` selects the right one based on build configuration. Each defines the API endpoint and OAuth issuer.

### Authentication
OAuth 2.0 via `OAuthAuthenticator` from the DataCapturing SDK, using the AppAuth library. Auth state is persisted in UserDefaults under `CyfaceApp.authStateKey`. `InitialViewModel` checks for a valid existing token and skips the login screen if present.

### Dependencies (Swift Package Manager)
- **DataCapturing** (`ios-sensor-library` v14.x) — core SDK providing `Measurement`, `SensorCapturer`, `LocationCapturer`, `OAuthAuthenticator`
- **AppAuth** — OAuth 2.0 / OIDC
- **SwiftProtobuf** — protobuf serialization
- **DataCompression** — compression utilities

### Testing
- Unit tests use the **Swift Testing** framework (`@Test`, `#expect`)
- UI tests use **XCTest**
- Test `CurrentMeasurementViewModel` by injecting a `PassthroughSubject<Message, Never>` via a mock `Measurement`
- UI tests launch the app with `XCUIApplication.launchCyface(loggedIn:)` (`cyfaceappUITests/Support/`). It passes `-UITest`, which makes `AppDependencies.fromLaunchArguments()` (Debug builds only) use a fake login (`UITestAuthenticator`), an empty in-memory database and no upload. So UI tests reach every screen without a server. `-UITestLoggedIn NO` starts on the login screen.
- UI tests find elements through screen objects (`cyfaceappUITests/Support/Screens.swift`) and accessibility identifiers (`de.cyface.app.…`). Add an identifier and extend the screen object for every new control a test needs.
- Run the UI tests without parallel testing (`-parallel-testing-enabled NO`) on a booted simulator. Before CY-6965 the first launch on a cold simulator blocked for minutes, since the location authorization status was read on the main thread. Never read `CLLocationManager.authorizationStatus` on the main thread; react to `locationManagerDidChangeAuthorization(_:)` instead.
- The location permission dialog appears on the first tap on Start, not at app start. The UI tests accept it with `allowSystemPermissions()`.

### CI/CD
GitHub Actions (`.github/workflows/swift.yml`) runs the unit tests (job `test`) and the UI tests without the launch performance tests (job `ui-test`) on every push/PR to `main` (macOS 26 runner, first available iPhone simulator). Pushing a version tag (`v1.2.3`) or a manual dispatch additionally archives, signs and uploads the build to App Store Connect, using the GitHub run number as build number. Submitting the uploaded build for App Review is still done manually in App Store Connect.
