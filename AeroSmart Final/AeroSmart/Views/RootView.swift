import SwiftUI
import SwiftData

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
