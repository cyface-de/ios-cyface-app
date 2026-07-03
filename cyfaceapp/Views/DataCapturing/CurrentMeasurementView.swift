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

import SwiftUI

/// A view showing information about the currently captured measurement.
///
/// It shows details about the GPS fix, duration of the measurement, current location, speed and distance traveled.
///
struct CurrentMeasurementView: View {
    /// The view model used to hold the state of the currently captured measurement.
    @State var viewModel: CurrentMeasurementViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("GPS Fix")
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: viewModel.hasFix)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20.0)
                }
                Spacer()
                HStack {
                    Text("Distance")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.distance)
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Speed")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.speed)
                        .lineLimit(1)
                }
            }.frame(maxHeight: .infinity)
            VStack {
                HStack(alignment: .top) {
                    Text("Duration")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.duration)
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Latitude")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.latitude)
                        .lineLimit(1)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text("Longitude")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.longitude)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    CurrentMeasurementView(
        viewModel: MockCurrentMeasurementViewModel()
    )
    .tint(.cyfaceGreen)
}
