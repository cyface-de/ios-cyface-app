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

import Foundation
import Testing
@testable import cyfaceapp

/// Checks that the legal documents link to the correct language version of the Cyface website.
struct LegalDocumentTests {

    @Test func germanLinks() {
        #expect(LegalDocument.imprint.url(forLanguage: "de") == URL(string: "https://cyface.de/impressum"))
        #expect(LegalDocument.privacyPolicy.url(forLanguage: "de") == URL(string: "https://cyface.de/datenschutz"))
    }

    @Test(arguments: ["en", "fr", nil])
    func englishLinksForAllOtherLanguages(languageCode: String?) {
        #expect(LegalDocument.imprint.url(forLanguage: languageCode) == URL(string: "https://cyface.de/en/legal-notice"))
        #expect(LegalDocument.privacyPolicy.url(forLanguage: languageCode) == URL(string: "https://cyface.de/en/privacy"))
    }
}
