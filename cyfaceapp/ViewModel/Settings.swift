/*
 * Copyright 2021-2025 Cyface GmbH
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
import OSLog

/**
 Access, write and react to changes within the apps settings.
 */
protocol Settings: NSObject {
    /// The toggle to activate or deactivate automatic data syncrhonization.
    var synchronizeData: Bool { get set }

    /**
     Add the provided `UploadToggleChangedListener` to the objects that are notified each time the user changes whether the app should upload data or not.
     */
    func add(uploadToggleChangedListener listener: UploadToggleChangedListener)
}

/**
 An implementation of the ``Settings`` protocol using an actual plist property file to store the setting values.

 This class allows access to the applications settings, which can be adapted view the devices settings menu.
 Among these settings are the credentials to access a Cyface server as well as the URL to that server.
 There is also the information on whether data should be synchronized automatically or not.

 Additionally there are several hidden settings for managed information, like the last authenticated server and the last already accepted privacy policy.

 */
class PropertySettings: NSObject, Settings {
    // MARK: - Constants
    /// The settings key for the toggle to activate or deactivate automatic data syncrhonization.
    private static let syncToggleKey = "de.cyface.sync_toggle"

    // MARK: - Properties
    /// Wether to synchronize data before the last settings change. This needs to be stored here, so we can identify if a settings change happened due to the synchronization toggle changing.
    private var oldSynchronizeData: Bool?
    /// A list of listeners who are informed every time the synchronization toggle was switched.
    private var synchronizationToggleChangedListener: [UploadToggleChangedListener] = []

    /// The toggle to activate or deactivate automatic data syncrhonization.
    var synchronizeData: Bool {
        get {
            UserDefaults.standard.bool(forKey: PropertySettings.syncToggleKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.syncToggleKey)
        }
    }

    // MARK: - Initializers
    /// A no-argument initializer setting up the settings and starting surveillance of setting changes.
    override init() {
        super.init()
        guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension: "bundle") else {
            fatalError("Unable to load Settings bundle from main bundle!")
        }
        let settingsUrl = settingsBundle.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf: settingsUrl)!
        guard let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] else {
            fatalError()
        }

        var defaultsToRegister = [String: Any]()

        for preference in preferences {
            guard let key = preference["Key"] as? String else {
                NSLog("Key not found")
                continue
            }

            defaultsToRegister[key] = preference["DefaultValue"]
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onSettingsChanged(notification:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Methods
    /**
     Method called on each change to a setting. It notifies listeners registerd as `serverUrlChangedListener` about changes to the server URL.

     - Parameter notification: A notification that contains the current settings for easy and fast access
     */
    @objc
    private func onSettingsChanged(notification: NSNotification) {
        os_log("System settings changed!")
        guard (notification.object as? UserDefaults) != nil else {
            return
        }

        if oldSynchronizeData != synchronizeData {
            onSynchronizeDataToggleChanged()
        }
    }

    /// Called if the user changed the synchronization toggle via the application system settings.
    private func onSynchronizeDataToggleChanged() {
        for listener in synchronizationToggleChangedListener {
            listener.to(upload: synchronizeData)
        }
    }

    /// Adds the provided `listener` to be informed about changes to the upload toggle status.
    func add(uploadToggleChangedListener listener: UploadToggleChangedListener) {
        synchronizationToggleChangedListener.append(listener)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UploadToggleChangedListener
protocol UploadToggleChangedListener {
    /// Called with the value the upload toggle was changed to.
    func to(upload: Bool)
}

// MARK: - PreviewSettings
class PreviewSettings: NSObject, Settings {

    var synchronizeData: Bool = false

    func add(uploadToggleChangedListener listener: UploadToggleChangedListener) {
        // Nothing to do here.
    }
}
