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
import DataCapturing

/**
 The main view of the application, combining an overview of all the captured measurements and control elements to run data capturing.
 */
struct MeasurementView: View {
    /// If `true` an error message is shown to the user.
    @State var showError = true
    /// The error message to show if `showError` is true.
    @State var viewModel: MeasurementViewModel
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack {
            List {
                ForEach($viewModel.finishedMeasurements) { $row in
                        MeasurementListView(measurementViewModel: $row)
                    }
                .onDelete(perform: deleteMeasurements)
            }
            .accessibilityIdentifier("de.cyface.app.list.measurements")

         if viewModel.isCurrentlyCapturing || viewModel.isPaused {
             CurrentMeasurementView(viewModel: viewModel.currentMeasurementViewModel())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("de.cyface.app.view.currentmeasurement")
            }

            ModalitySelectorView(modalitySelectorViewModel: viewModel.modalitySelectorVM)

            HStack {
                Button(action: {
                    viewModel.start()
                }) {
                    Image(systemName: "play.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isCurrentlyCapturing)
                .accessibilityLabel("Start")
                .accessibilityIdentifier("de.cyface.app.button.start")

                Button(action: {
                    viewModel.pause()
                }) {
                    Image(systemName: "pause.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isPaused || (!viewModel.isPaused && !viewModel.isCurrentlyCapturing))
                .accessibilityLabel("Pause")
                .accessibilityIdentifier("de.cyface.app.button.pause")

                Button(action: {
                    viewModel.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.isCurrentlyCapturing && !viewModel.isPaused)
                .accessibilityLabel("Stop")
                .accessibilityIdentifier("de.cyface.app.button.stop")
            }
            .frame(maxWidth: .infinity)
        }
            // This screen has no text input, so it never needs to make room for the keyboard.
            // After a login, in which the user typed on the login page, SwiftUI sometimes still reserves the space of the keyboard. Without this, the controls then sit in the middle of the screen (CY-6967).
            // Remove this, if a text field is ever added to this screen.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: {
                        viewModel.startSynchronization()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Upload")
                    .accessibilityIdentifier("de.cyface.app.button.sync")
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        Task {
                            await viewModel.logout()
                            onLoggedOut()
                        }
                    }) {
                        Image(systemName: "power.circle")
                    }
                    .accessibilityLabel("Logout")
                    .accessibilityIdentifier("de.cyface.app.button.logout")
                }

                ToolbarItem(placement: .primaryAction) {
                    LegalInformationButton()
                }
            }
            .frame(maxWidth: .infinity)
            .alert("Error", isPresented: $viewModel.showError, actions: {
            }, message: {
                Text(viewModel.error?.localizedDescription ?? "")
            })
    }

    @MainActor
    private func onLoggedOut() {
        isLoggedIn = false
    }
    /// Handles calling delete on one or more measurements.
    private func deleteMeasurements(at offsets: IndexSet) {
        viewModel.deleteMeasurements(at: offsets)
    }
}

#Preview("Default View") {
    @Previewable @State var isLoggedIn = true

    MeasurementView(
        viewModel: MockMeasurementViewModel(),
        isLoggedIn: $isLoggedIn
    )
    .tint(Color("Cyface-Green"))
}

#Preview("Measurment View with Error Dialog") {
    @Previewable @State var isLoggedIn = true

    MeasurementView(
        viewModel: MockMeasurementViewModel(
        showError: true,
        error: MeasurementError.isPaused
    ), isLoggedIn: $isLoggedIn)
    .tint(Color("Cyface-Green"))
}
