/*
 * Copyright 2022-2026 Cyface GmbH
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

    func calculateCoveredDistance(measurement: MeasurementMO) -> Double {
        let tracks = measurement.typedTracks()
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

    func duration(measurement: MeasurementMO) -> TimeInterval {
        measurement.typedTracks().map { track in
            track.typedLocations().last?.time?.timeIntervalSince(track.typedLocations().first!.time!) ?? 0.0
        }.reduce(0.0) { (partialResult: TimeInterval, next: TimeInterval) -> TimeInterval in
            return partialResult + next
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
