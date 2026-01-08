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
    var selectedModality: Modalities {
        didSet {
            debugPrint("selectedModality: Setting Modality to \(selectedModality.dbValue) on Measurement \(String(describing: currentMeasurement))")
            currentMeasurement?.changeModality(to: selectedModality.dbValue)
        }
    }
    var currentMeasurement: DataCapturing.Measurement? {
        didSet {
            debugPrint("currentMeasurement: Setting Modality to \(selectedModality.dbValue) on Measurement \(String(describing: currentMeasurement))")
            currentMeasurement?.changeModality(to: selectedModality.dbValue)
        }
    }

    init(selectedModality: Modalities) {
        self.selectedModality = selectedModality
    }
}

extension ProductionModalitySelectorViewModel: ModalitySelectorViewModel {
    
}
