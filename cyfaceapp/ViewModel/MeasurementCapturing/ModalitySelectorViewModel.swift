/*
 * Copyright 2026 Cyface GmbH
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

@MainActor
protocol ModalitySelectorViewModel {
    // MARK: Properties
    var selectedModality: Modalities { get set }
    var currentMeasurement: DataCapturing.Measurement? { get set }
}

@MainActor
@Observable
class ProductionModalitySelectorViewModel {
    static var persistenceKey = "de.cyface.app.ModalitiySelectorViewModel.selectedModality"

    var selectedModality: Modalities {
        didSet {
            debugPrint("selectedModality: Setting Modality to \(selectedModality.dbValue) on Measurement \(String(describing: currentMeasurement))")
            currentMeasurement?.changeModality(to: selectedModality.dbValue)
            UserDefaults.standard.set(selectedModality.rawValue, forKey: ProductionModalitySelectorViewModel.persistenceKey)
        }
    }
    var currentMeasurement: DataCapturing.Measurement? {
        didSet {
            debugPrint("currentMeasurement: Setting Modality to \(selectedModality.dbValue) on Measurement \(String(describing: currentMeasurement))")
            currentMeasurement?.changeModality(to: selectedModality.dbValue)
        }
    }

    init() {
        self.selectedModality = Modalities(rawValue: UserDefaults.standard.string(forKey: ProductionModalitySelectorViewModel.persistenceKey) ?? Modalities.defaultSelection.rawValue) ?? Modalities.defaultSelection
    }
}

extension ProductionModalitySelectorViewModel: ModalitySelectorViewModel {
    
}
