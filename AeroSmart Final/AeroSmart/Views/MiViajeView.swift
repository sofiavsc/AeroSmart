import SwiftUI
import SwiftData

struct MiViajeView: View {
    let user: User

    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departure) private var allTrips: [Trip]

    private var nextTrip: Trip? {
        for trip in allTrips where trip.ownerEmail == user.email && !trip.isCancelled && trip.arrival > Date() {
            return trip
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            if let trip = nextTrip {
                TripDetailView(trip: trip)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.sunset)
                Text("Todavía no hay maletas que hacer")
                    .font(.title2.bold())
                Text("Cuando reserves, aquí vas a ver tu pase de abordar, el clima del destino y tu checklist.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                AeroButton(title: "Buscar vuelos", systemImage: "magnifyingglass") {
                    appState.selectedTab = 0
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
}
