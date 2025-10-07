//
//  InitialView.swift
//  cyfaceapp
//
//  Created by Klemens Muthmann on 30.09.25.
//

import SwiftUI
import DataCapturing

/*
 "apiEndpoint":"https://s1-b.cyface.de/provider/api/v2/",
 "redirectUri":"de.cyface.app.r4r:/oauth2redirect/",
 "clientId":"ios-app",
 "issuer":"https://s1-a.cyface.de/realms/rfr",
 "incentivesUrl":"https://staging.cyface.de/incentives/api/v1/",
 "uploadEndpoint":"https://s1-b.cyface.de/api/v4/",
 "enableSentryTracing": "true"
 */

struct InitialView: View {
    @State private var viewModel = InitialViewModel()
    private var authenticator = OAuthAuthenticator(
        issuer: URL(string: "https://s1-a.cyface.de/realms/rfr")!,
        redirectUri: URL(string: "de.cyface.app:/oauth2redirect/")!,
        apiEndpoint: URL(string: "https://s1-b.cyface.de/provider/api/v2/")!,
        clientId: "cyface-ios-app"
    )

    var body: some View {
        NavigationStack {
            if viewModel.isAuthenticated {
                Text("Welcome! You are authenticated!")

                Button("Simulate Logout") {
                    viewModel.isAuthenticated = false
                }
                .padding()
            } else {
                AuthenticationView(authenticator: authenticator, viewModel: viewModel)
                    .onOpenURL(perform: { url in
                        authenticator.callback(url: url)
                    })
            }
        }
    }
}

#Preview {
    InitialView()
}
