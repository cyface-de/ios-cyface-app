/*
 * Copyright 2026 Cyface GmbH
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
import SafariServices

/**
 The legal documents of Cyface GmbH, which must be reachable from within the app.

 The documents are hosted on the Cyface website, which provides a German and an English version of each.
 The German version is the legally binding one and is used whenever the app runs in German.
 */
enum LegalDocument: CaseIterable, Identifiable {
    /// The legal notice ("Impressum") as required by § 5 DDG.
    case imprint
    /// The privacy policy ("Datenschutzerklärung").
    case privacyPolicy

    var id: Self { self }

    /// The localized title shown to the user for this document.
    var title: LocalizedStringKey {
        switch self {
        case .imprint:
            return "Imprint"
        case .privacyPolicy:
            return "Privacy Policy"
        }
    }

    /// The SF Symbol shown next to the ``title``.
    var systemImage: String {
        switch self {
        case .imprint:
            return "building.2"
        case .privacyPolicy:
            return "hand.raised"
        }
    }

    /**
     The URL of this document in the provided language.

     - Parameter languageCode: An ISO 639 language code like `de` or `en`. Every language except German gets the English version.
     */
    func url(forLanguage languageCode: String?) -> URL {
        let isGerman = languageCode == "de"
        switch self {
        case .imprint:
            return isGerman ? URL(string: "https://cyface.de/impressum")! : URL(string: "https://cyface.de/en/legal-notice")!
        case .privacyPolicy:
            return isGerman ? URL(string: "https://cyface.de/datenschutz")! : URL(string: "https://cyface.de/en/privacy")!
        }
    }

    /// The URL of this document in the language the app's user interface is currently shown in.
    var url: URL {
        url(forLanguage: Bundle.main.preferredLocalizations.first)
    }
}

/**
 A view listing links to all the ``LegalDocument``s, like the imprint and the privacy policy.

 It is reachable from the login screen as well as from the main screen, so users can access the documents before and after registering.
 The documents open in an in-app Safari view, so the user does not leave the app.
 */
struct LegalInformationView: View {
    /// The document currently shown in the in-app Safari view, or `nil` if none is shown.
    @State private var shownDocument: LegalDocument?

    var body: some View {
        List(LegalDocument.allCases) { document in
            Button {
                shownDocument = document
            } label: {
                Label(document.title, systemImage: document.systemImage)
            }
        }
        .navigationTitle("Legal Information")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shownDocument) { document in
            SafariView(url: document.url)
                .ignoresSafeArea()
        }
    }
}

/**
 Shows a web page inside the app, using an `SFSafariViewController`.
 */
struct SafariView: UIViewControllerRepresentable {
    /// The web page to show.
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Nothing to do here, since the URL of an `SFSafariViewController` cannot change after creation.
    }
}

/**
 A toolbar button opening the ``LegalInformationView``.
 */
struct LegalInformationButton: View {
    var body: some View {
        NavigationLink {
            LegalInformationView()
        } label: {
            Image(systemName: "info.circle")
        }
        .accessibilityLabel("Legal Information")
        .accessibilityIdentifier("de.cyface.app.button.legalinformation")
    }
}

#Preview {
    NavigationStack {
        LegalInformationView()
    }
    .tint(Color("Cyface-Green"))
}
