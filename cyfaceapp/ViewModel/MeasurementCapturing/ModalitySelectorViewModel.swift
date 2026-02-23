//
//  ModalitySelectorViewModel.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 06.01.26.
//
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
