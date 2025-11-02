/*
 * Copyright 2022-2025 Cyface GmbH
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

import SwiftUI

/**
 A single list entry in the list of measurements, showing a general overview of the measurement.
 */
struct MeasurementListView: View {
    /// The view model containing the current data of the measurement and handling connection to data storage.
    @Binding var measurementViewModel: MeasurementListEntryViewModel

    var body: some View {
        HStack {
        VStack {
            HStack {
                Text("Measurement \(measurementViewModel.id)")
                Spacer()
            }

            HStack {
                Text("Distance")
                Spacer()
                Text("\(measurementViewModel.formattedDistance)")
            }


        }

            Group {
                switch measurementViewModel.syncStatus {
                case .local:
                    Image(systemName: "iphone")
                        .resizable()
                        .scaledToFit()
                        .imageScale(.small)
                case .synchronizing:
                    ProgressView()
                case .synchronized:
                    Image(systemName: "checkmark.icloud")
                        .resizable()
                        .scaledToFit()
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                }
            }
            .padding()
            .frame(width: 50)
            .frame(maxHeight: .infinity)
        }
    }
}

#Preview {
        let measurementViewModel = MeasurementListEntryViewModel(distance: 10.0, id: 2)
    MeasurementListView(measurementViewModel: .constant(measurementViewModel))

    let synchronizingViewModel = MeasurementListEntryViewModel(syncStatus: .synchronizing, distance: 10.0, id: 2)
    MeasurementListView(measurementViewModel: .constant(synchronizingViewModel))

    let synchronizationFailedViewModel = MeasurementListEntryViewModel(syncStatus: .failed, distance: 10.0, id: 2)
    MeasurementListView(measurementViewModel: .constant(synchronizationFailedViewModel))

    MeasurementListView(measurementViewModel: .constant(MeasurementListEntryViewModel(distance: 2364.82374, id: 4)))
}
