//
//  PersistenceLayer.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 28.10.25.
//
import DataCapturing
import CoreData

class PersistenceLayer {
    let coreDataStack: CoreDataStack

    init(_ coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func update(measurement: FinishedMeasurement, with: (MeasurementMO) throws -> ()) throws {
        try coreDataStack.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier=%@", NSNumber(value: measurement.identifier))
            request.fetchLimit = 1
            let loadedMeasurements = try request.execute()

            guard let loadedMeasurement = loadedMeasurements.first else {
                throw CyfaceError.noSuchMeasurement(identifier: measurement.identifier)
            }

            try with(loadedMeasurement)

            try context.save()
        }
    }

    func on<T>(measurementIdentifiedBy: UInt64, execute: (MeasurementMO) throws -> T) throws -> T {
        try coreDataStack.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier=%@", NSNumber(value: measurementIdentifiedBy))
            request.fetchLimit = 1

            guard let loadedMeasurement = try request.execute().first else {
                throw CyfaceError.noSuchMeasurement(identifier: measurementIdentifiedBy)
            }

            return try execute(loadedMeasurement)
        }
    }

    /// Delete a Measurement from the database.
    func delete(measurementIdentifiedBy: UInt64) throws {
        try coreDataStack.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier=%@", NSNumber(value: measurementIdentifiedBy))
            request.fetchLimit = 1

            guard let loadedMeasurement = try request.execute().first else {
                fatalError("Tried to delete a measurement that doesn't exist")
            }
            
            context.delete(loadedMeasurement)
            try context.save()
        }
    }
}
