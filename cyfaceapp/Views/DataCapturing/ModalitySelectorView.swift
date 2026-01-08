/*
 * Copyright 2022 Cyface GmbH
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
 A picker used to select the current modality for the data measurement.
 */
struct ModalitySelectorView: View {
    //@Binding var selectedModality: Modalities
    @State var modalitySelectorViewModel: ModalitySelectorViewModel

    var body: some View {
        Picker("Modality", selection: $modalitySelectorViewModel.selectedModality) {
            Text(Modalities.bicycle.uiValue).tag(Modalities.bicycle)
            Text(Modalities.car.uiValue).tag(Modalities.car)
            Text(Modalities.walking.uiValue).tag(Modalities.walking)
            Text(Modalities.bus.uiValue).tag(Modalities.bus)
            Text(Modalities.train.uiValue).tag(Modalities.train)
        }.pickerStyle(.segmented)
    }
}

#Preview {
    ModalitySelectorView(
        modalitySelectorViewModel: ProductionModalitySelectorViewModel(selectedModality: Modalities.defaultSelection)
    )
}
