import SwiftUI
import SwiftData

struct MyTripsView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.departure) private var allTrips: [Trip]

    private var upcoming: [Trip] {
        var result: [Trip] = []
        for trip in allTrips where trip.ownerEmail == user.email && !trip.isCancelled && trip.arrival > Date() {
            result.append(trip)
        }
        return result
    }

    private var history: [Trip] {
        var result: [Trip] = []
        for trip in allTrips where trip.ownerEmail == user.email && (trip.isCancelled || trip.arrival <= Date()) {
            result.append(trip)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                if upcoming.isEmpty && history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "suitcase.rolling.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Theme.sunset)
                        Text("Sin viajes todavía")
                            .font(.title3.bold())
                        Text("Cuando reserves, tus viajes aparecerán aquí.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    List {
                        if !upcoming.isEmpty {
                            Section {
                                ForEach(upcoming, id: \.bookingCode) { trip in
                                    row(trip)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                trip.isCancelled = true
                                                try? modelContext.save()
                                            } label: {
                                                Label("Cancelar", systemImage: "xmark")
                                            }
                                        }
                                }
                            } header: {
                                Text("Próximos")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }

                        if !history.isEmpty {
                            Section {
                                ForEach(history, id: \.bookingCode) { trip in
                                    row(trip)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                modelContext.delete(trip)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                Text("Historial de viajes")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Mis viajes")
        }
    }

    private func row(_ trip: Trip) -> some View {
        NavigationLink {
            TripDetailView(trip: trip)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(trip.originCode) → \(trip.destinationCode)")
                        .font(.title3.bold())
                    Spacer()
                    StatusPill(text: trip.status(at: Date()).title, color: trip.status(at: Date()).color)
                }
                Text("\(trip.originCity) a \(trip.destinationCity)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                HStack {
                    Label(trip.departure.shortDayText, systemImage: "calendar")
                    Spacer()
                    Label("Asiento \(trip.seat)", systemImage: "person.fill")
                    Spacer()
                    Text(trip.flightNumber)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }
            .aeroCard()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
