/*
 * Copyright 2025-2026 Cyface GmbH
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

/**
 Protocol for an old style delegate for handling events reported by the AppAuth framework during authentication.

 - Author: Klemens Muthmann
 */
protocol LoginViewControllerDelegate {
    /// Handle a successful login.
    func onLoggedIn()
    /// Handle an error occuring during the login process.
    func onError(error: Error)
}
