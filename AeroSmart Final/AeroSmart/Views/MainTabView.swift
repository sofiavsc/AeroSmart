import SwiftUI

struct MainTabView: View {
    let user: User

    @State private var appState = AppState()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Tab("Volar", systemImage: "airplane", value: 0) {
                ExploreView(user: user)
            }
            Tab("Mi Viaje", systemImage: "ticket.fill", value: 1) {
                MiViajeView(user: user)
            }
            Tab("En vivo", systemImage: "dot.radiowaves.left.and.right", value: 2) {
                LiveView()
            }
            Tab("Viajes", systemImage: "suitcase.fill", value: 3) {
                MyTripsView(user: user)
            }
            Tab("Perfil", systemImage: "person.crop.circle.fill", value: 4) {
                ProfileView(user: user)
            }
        }
        .tint(Theme.sunset)
        .environment(appState)
    }
}
