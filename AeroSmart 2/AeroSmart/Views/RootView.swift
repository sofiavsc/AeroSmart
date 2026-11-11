//
//  RootView.swift
//  AeroSmart
//

import SwiftUI
import SwiftData

// Decide qué mostrar: inicio de sesión o la app.
struct RootView: View {
    @Query private var users: [User]
    @AppStorage("sessionEmail") private var sessionEmail = ""

    private var currentUser: User? {
        for user in users where user.email == sessionEmail {
            return user
        }
        return nil
    }

    var body: some View {
        if let user = currentUser {
            MainTabView(user: user)
        } else {
            AuthView(sessionEmail: $sessionEmail)
        }
    }
}
