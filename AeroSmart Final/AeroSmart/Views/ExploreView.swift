import SwiftUI
import SwiftData

struct ExploreView: View {
    let user: User

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDestination]
    @Query(sort: \Trip.departure) private var allTrips: [Trip]

    @AppStorage("lastOrigin") private var originCode = "TAM"
    @State private var destinationCode = "CUN"
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var showResults = false
    @State private var showAlert = false
    @State private var swapAngle = 0.0

    private let palettes: [[Color]] = [
        [Color(red: 1.00, green: 0.46, blue: 0.38), Color(red: 1.00, green: 0.73, blue: 0.30)],
        [Color(red: 0.45, green: 0.30, blue: 0.85), Color(red: 0.85, green: 0.45, blue: 0.80)],
        [Color(red: 0.95, green: 0.33, blue: 0.52), Color(red: 1.00, green: 0.60, blue: 0.45)],
        [Color(red: 0.25, green: 0.20, blue: 0.60), Color(red: 0.45, green: 0.55, blue: 0.95)],
        [Color(red: 0.85, green: 0.40, blue: 0.20), Color(red: 0.98, green: 0.80, blue: 0.40)]
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        searchCard
                        nextTripCard
                        favoritesRow
                        destinationsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showResults) {
                FlightResultsView(
                    originCode: originCode,
                    destinationCode: destinationCode,
                    date: date,
                    user: user
                )
            }
            .alert("Revisa tu búsqueda", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("El origen y el destino deben ser diferentes.")
            }
            .onChange(of: appState.searchResetToken) {
                showResults = false
            }
        }
    }

    private var firstName: String {
        return user.name.split(separator: " ").first.map { String($0) } ?? user.name
    }

    private var greeting: (text: String, icon: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return ("Buenos días", "sun.horizon.fill") }
        if hour < 19 { return ("Buenas tardes", "sun.max.fill") }
        return ("Buenas noches", "moon.stars.fill")
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Label(greeting.text, systemImage: greeting.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.mango)
                Text("\(firstName), ¿a dónde\nvolamos hoy?")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
            }
            Spacer()
            Image(systemName: "airplane.departure")
                .font(.system(size: 30))
                .foregroundStyle(Theme.sunsetGradient)
        }
        .padding(.top, 16)
    }

    private var searchCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 8) {
                airportColumn(title: "Origen", selection: $originCode)

                Button {
                    withAnimation(.spring) {
                        let temp = originCode
                        originCode = destinationCode
                        destinationCode = temp
                        swapAngle += 180
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.headline)
                        .foregroundStyle(Theme.night)
                        .frame(width: 42, height: 42)
                        .background(Theme.sunsetGradient)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(swapAngle))
                }

                airportColumn(title: "Destino", selection: $destinationCode)
            }

            Divider().background(Color.white.opacity(0.2))

            HStack {
                Label("¿Cuándo sales?", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                DatePicker("Fecha", selection: $date, in: Date()..., displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.sunset)
            }

            if let from = Airport.find(originCode), let to = Airport.find(destinationCode), originCode != destinationCode {
                Text("\(Int(Airport.distanceKm(from, to))) km de vuelo · ≈ \(durationText(Int(Airport.distanceKm(from, to) / 760 * 60) + 45))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AeroButton(title: "Buscar vuelos", systemImage: "magnifyingglass") {
                if originCode == destinationCode {
                    showAlert = true
                } else {
                    showResults = true
                }
            }
        }
        .aeroCard()
    }

    private func airportColumn(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.55))
            Text(selection.wrappedValue)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
            Picker(title, selection: selection) {
                ForEach(Airport.all, id: \.code) { airport in
                    Text("\(airport.city) (\(airport.code))").tag(airport.code)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Theme.sunset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nextTrip: Trip? {
        for trip in allTrips where trip.ownerEmail == user.email && !trip.isCancelled && trip.arrival > Date() {
            return trip
        }
        return nil
    }

    @ViewBuilder
    private var nextTripCard: some View {
        if let trip = nextTrip {
            Button {
                appState.selectedTab = 1
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "ticket.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.sunset)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Tu próximo viaje")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(trip.originCode) → \(trip.destinationCode) · \(trip.departure.shortDayText)")
                            .font(.headline)
                        Text("Checklist \(trip.doneCount) de \(trip.checklist.count) completado")
                            .font(.caption)
                            .foregroundStyle(Theme.mint)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .aeroCard()
            }
            .buttonStyle(.plain)
        }
    }

    private func isFavorite(_ code: String) -> Bool {
        for favorite in favorites where favorite.ownerEmail == user.email && favorite.code == code {
            return true
        }
        return false
    }

    private func toggleFavorite(_ code: String) {
        for favorite in favorites where favorite.ownerEmail == user.email && favorite.code == code {
            modelContext.delete(favorite)
            try? modelContext.save()
            return
        }
        modelContext.insert(FavoriteDestination(ownerEmail: user.email, code: code))
        try? modelContext.save()
    }

    @ViewBuilder
    private var favoritesRow: some View {
        let mine = favorites.filter { $0.ownerEmail == user.email }
        if !mine.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Tus favoritos", systemImage: "heart.fill")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(mine, id: \.code) { favorite in
                            Button {
                                withAnimation(.spring) {
                                    destinationCode = favorite.code
                                }
                            } label: {
                                Label(Airport.cityName(favorite.code), systemImage: "heart.fill")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Theme.rose.opacity(0.2))
                                    .foregroundStyle(Theme.rose)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private func estimatedPrice(to destination: Airport) -> Int {
        guard let from = Airport.find(originCode) else { return 0 }
        let km = Airport.distanceKm(from, destination)
        return Int((650 + km * 1.05) / 10) * 10
    }

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Destinos que te pueden gustar")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Airport.all.indices, id: \.self) { index in
                        let airport = Airport.all[index]
                        if airport.code != originCode {
                            destinationCard(airport, colors: palettes[index % palettes.count])
                        }
                    }
                }
            }
        }
    }

    private func destinationCard(_ airport: Airport, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: airport.icon)
                    .font(.title2)
                Spacer()
                Button {
                    toggleFavorite(airport.code)
                } label: {
                    Image(systemName: isFavorite(airport.code) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFavorite(airport.code) ? Theme.rose : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            Spacer()
            Text(airport.city)
                .font(.title3.bold())
            Text(airport.tagline)
                .font(.caption)
                .opacity(0.9)
                .lineLimit(2)
            Text("desde ≈ $\(estimatedPrice(to: airport)) MXN")
                .font(.caption.bold())
                .padding(.top, 2)
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(width: 180, height: 200, alignment: .leading)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white, lineWidth: destinationCode == airport.code ? 3 : 0)
        )
        .onTapGesture {
            withAnimation(.spring) {
                destinationCode = airport.code
            }
        }
    }
}
