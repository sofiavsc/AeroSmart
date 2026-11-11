import SwiftUI
import SwiftData

struct SeatSelectionView: View {
    let flight: FlightOption
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var viewModel = SeatSelectionViewModel()
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 16) {
                    flightHeader

                    if viewModel.isLoading {
                        AirplaneLoader(text: "Consultando el mapa de asientos…")
                            .padding(.top, 50)
                    } else {
                        if let notice = viewModel.notice {
                            NoticeBanner(text: notice)
                        } else if viewModel.isLive {
                            NoticeBanner(text: "Mapa de asientos en vivo desde Duffel.", isLive: true)
                        }

                        assistantCard
                        legend

                        SeatMapView(
                            rows: viewModel.rows,
                            selectedDesignator: viewModel.selectedDesignator,
                            recommendedDesignator: viewModel.recommendedDesignator
                        ) { seat in
                            withAnimation {
                                viewModel.select(seat)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Elige tu asiento")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .task {
            await viewModel.load(flight: flight)
        }
        .alert("¡Reservación confirmada!", isPresented: $showConfirmation) {
            Button("Ver Mi Viaje") {
                finishBooking()
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var flightHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(flight.originCode) → \(flight.destinationCode)")
                    .font(.title3.bold())
                Text("\(flight.airline) · \(flight.flightNumber)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(flight.departure.hourText) – \(flight.arrival.hourText)")
                    .font(.subheadline.bold())
                Text(flight.departure.shortDayText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .aeroCard()
    }

    private var assistantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Asistente de asiento", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Theme.sunset)
                Spacer()
                Text("\(viewModel.availableCount) libres")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text("¿Qué te importa más? Elige y te digo cuál te conviene.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SeatPreference.allCases, id: \.self) { preference in
                        let active = viewModel.preferences.contains(preference)
                        Button {
                            withAnimation(.spring) {
                                viewModel.togglePreference(preference)
                            }
                        } label: {
                            Label(preference.rawValue, systemImage: active ? "checkmark" : preference.icon)
                                .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(active ? Theme.sunset : .white.opacity(0.12))
                    }
                }
            }

            if let seat = viewModel.recommendedSeat {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(Theme.mint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tu asiento ideal: \(seat.designator)")
                            .font(.subheadline.bold())
                        Text("\(seat.traits) · \(moneyText(seat.price, currency: seat.currency))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Button("Lo quiero") {
                        withAnimation {
                            viewModel.select(seat)
                        }
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.mint)
                    .foregroundStyle(Theme.night)
                }
                .padding(12)
                .background(Theme.mint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if !viewModel.preferences.isEmpty {
                Text("No hay asientos libres que coincidan.")
                    .font(.caption)
                    .foregroundStyle(Theme.mango)
            }
        }
        .aeroCard()
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Color.white.opacity(0.16), text: "Libre")
            legendItem(color: Theme.mango.opacity(0.4), text: "Más espacio")
            legendItem(color: Color.white.opacity(0.06), text: "Ocupado")
            legendItem(color: Theme.sunset, text: "Tu asiento")
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.7))
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(text)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let seat = viewModel.selectedSeat {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Asiento \(seat.designator)")
                            .font(.headline)
                        Text(seat.traits)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(totalText(for: seat))
                            .font(.headline)
                            .foregroundStyle(Theme.sunset)
                        Text("Vuelo + asiento")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            } else {
                Text("Toca un asiento libre en el mapa")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            AeroButton(
                title: "Reservar mi lugar",
                systemImage: "checkmark.circle.fill",
                isEnabled: viewModel.selectedSeat != nil
            ) {
                confirmBooking()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private func totalText(for seat: Seat) -> String {
        if seat.currency == flight.currency {
            return moneyText(flight.price + seat.price, currency: flight.currency)
        }
        return "\(moneyText(flight.price, currency: flight.currency)) + \(moneyText(seat.price, currency: seat.currency))"
    }

    private func confirmBooking() {
        guard let seat = viewModel.selectedSeat else { return }

        let trip = Trip.make(flight: flight, seat: seat, ownerEmail: user.email, isLiveSeatMap: viewModel.isLive)
        modelContext.insert(trip)
        for item in trip.buildChecklist() {
            modelContext.insert(item)
            item.trip = trip
        }
        try? modelContext.save()

        confirmationMessage = "Vuelo \(flight.flightNumber) \(flight.originCode) → \(flight.destinationCode)\nAsiento \(seat.designator) · Código \(trip.bookingCode)"
        showConfirmation = true
    }

    private func finishBooking() {
        appState.selectedTab = 1
        appState.searchResetToken += 1
    }
}
