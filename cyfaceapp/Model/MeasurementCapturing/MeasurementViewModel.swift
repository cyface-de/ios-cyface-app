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

protocol MeasurementViewModel {
    var isCurrentlyCapturing: Bool { get }
    var isPaused: Bool { get }
    func start()

    func pause()

    func stop()
}

@Observable class ProductionMeasurementViewModel {
    // TODO: Initialise correctly if measurement has been running in the background
    var isCurrentlyCapturing: Bool = false
    var isPaused: Bool = false
}

// MARK: - MeasurementViewModel adoption
extension ProductionMeasurementViewModel: MeasurementViewModel {
    func start() {
        debugPrint("Start Data Capturing")
        isCurrentlyCapturing = true
        isPaused = false
    }
    
    func pause() {
        debugPrint("Pause Data Capturing")
        isCurrentlyCapturing = false
        isPaused = true
    }
    
    func stop() {
        debugPrint("Stop Data Capturing")
        isCurrentlyCapturing = false
        isPaused = false
    }
    

}
