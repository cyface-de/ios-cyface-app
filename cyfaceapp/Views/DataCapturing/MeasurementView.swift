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
    /// The current application state.
    //@EnvironmentObject var appState: ApplicationState
    /// The authenticator used to login the user. This should contain the currently valid user to login and upload data.
    // TODO: var authenticator: CredentialsAuthenticator?
    /// The modality selected to capture data.
    @State var selectedModality = Modalities.defaultSelection
    /// If `true` an error message is shown to the user.
    @State var showError = true
    /// The error message to show if `showError` is true.
    //@State var errorMessage = ""
    /// If `true` the currently displayed error is dismissed.
    //var dismiss = false
    /// This is required to dimiss the view on a non recoverable error.
    /// More explanation here: https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
    //@Environment(\.presentationMode) var presentationMode
    @State var viewModel: MeasurementViewModel

    var body: some View {
        VStack {
            List {
    /*            ForEach($appState.measurements) { $row in
                        MeasurementListView(measurementViewModel: $row)
                    }
                .onDelete(perform: deleteMeasurements)*/
            }

         if viewModel.isCurrentlyCapturing || viewModel.isPaused {
             CurrentMeasurementView(viewModel: viewModel.currentMeasurementViewModel())
                    .fixedSize(horizontal: false, vertical: true)
            }

            ModalitySelectorView(selectedModality: $selectedModality)

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
            }
            .frame(maxWidth: .infinity)
        }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: {
//                        appState.sync()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        DispatchQueue.main.async {
//                            appState.isLoggedIn = false
//                            appState.settings.authenticatedServerUrl = nil
                        }
                    }) {
                        Image(systemName: "power.circle")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .alert("Error", isPresented: $viewModel.showError, actions: {
                // actions
            }, message: {
                Text(viewModel.error?.localizedDescription ?? "")
            })
            .onAppear() {
                // TODO: appState.startSynchronization(authenticator: self.authenticator)
            }
    }

    /// Handles calling delete on one or more measurements.
    /*private func deleteMeasurements(at offsets: IndexSet) {
        do {
            try appState.deleteMeasurements(at: offsets)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }*/
}

#Preview("Default View") {
    MeasurementView(viewModel: MockMeasurementViewModel())
        .tint(Color("Cyface-Green"))
}

#Preview("Measurment View with Error Dialog") {
    MeasurementView(viewModel: MockMeasurementViewModel(
        showError: true,
        error: MeasurementError.noCurrentMeasurement
    ))
    .tint(Color("Cyface-Green"))
}
