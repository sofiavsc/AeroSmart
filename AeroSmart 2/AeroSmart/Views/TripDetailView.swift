//
//  TripDetailView.swift
//  AeroSmart
//

import SwiftUI
import SwiftData

// Pantalla "Mi Viaje": pase de abordar, estado, cuenta regresiva y checklist inteligente.
struct TripDetailView: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext

    // Reloj que se actualiza solo cada 30 s (patrón Counter de la clase 10)
    @State private var clock = TripClock()
    // Clima del destino (API Open-Meteo)
    @State private var weatherViewModel = WeatherViewModel()

    // 0 = hora real; 1...4 = escenarios para la demo
    @State private var simulation = 0
    @State private var showCancelAlert = false

    private let scenarioNames = ["Real", "-20 h", "-90 min", "-30 min", "En vuelo"]

    private func simulatedNow(real: Date) -> Date {
        switch simulation {
        case 1: return trip.departure.addingTimeInterval(-20 * 3600)
        case 2: return trip.departure.addingTimeInterval(-90 * 60)
        case 3: return trip.departure.addingTimeInterval(-30 * 60)
        case 4: return trip.departure.addingTimeInterval(30 * 60)
        default: return real
        }
    }

    var body: some View {
        let now = simulatedNow(real: clock.now)
        let status = trip.status(at: now)

        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 16) {
                    passCard(status: status)

                    if status == .cancelled {
                        cancelledCard
                    } else {
                        countdownCard(now: now, status: status)
                        nextStepCard(status: status)
                        weatherCard
                        checklistCard(status: status)
                        infoCard
                        simulatorCard
                        cancelButton(status: status)
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            clock.start()
        }
        .onDisappear {
            clock.stop()
        }
        .task {
            if let airport = Airport.find(trip.destinationCode) {
                await weatherViewModel.getWeather(for: airport)
            }
        }
        .navigationTitle("\(trip.originCode) → \(trip.destinationCode)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Cancelar este viaje?", isPresented: $showCancelAlert) {
            Button("Cancelar viaje", role: .destructive) {
                trip.isCancelled = true
                try? modelContext.save()
            }
            Button("Volver", role: .cancel) { }
        } message: {
            Text("El viaje pasará a tu historial como cancelado.")
        }
    }

    // MARK: Clima en el destino
    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Clima en \(trip.destinationCity)", systemImage: "location.fill")
                .font(.headline)

            if weatherViewModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Theme.mango)
                    Text("Revisando el cielo…")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else if let current = weatherViewModel.weather?.current {
                HStack(spacing: 16) {
                    Image(systemName: current.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.mango)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.temperatureText)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                        Text(current.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "suitcase.fill")
                        .foregroundStyle(Theme.mango)
                    Text(current.packingTip)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.mango.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let message = weatherViewModel.errorMessage {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(Theme.mango)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aeroCard()
    }

    // MARK: Pase de abordar
    private func passCard(status: TripStatus) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                HStack {
                    Text(trip.airline)
                        .font(.subheadline.bold())
                    Text(trip.flightNumber)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    StatusPill(text: status.title, color: status.color)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.originCode)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                        Text(trip.originCity)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(trip.departure.hourText)
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: status.icon)
                            .font(.title2)
                            .foregroundStyle(status.color)
                        Text(durationText(trip.durationMinutes))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(trip.destinationCode)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                        Text(trip.destinationCity)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(trip.arrival.hourText)
                            .font(.title3.bold())
                    }
                }
            }
            .padding(18)

            dashedDivider

            VStack(spacing: 16) {
                HStack {
                    infoCell(title: "Fecha", value: trip.departure.shortDayText)
                    Spacer()
                    infoCell(title: "Terminal", value: trip.terminal)
                    Spacer()
                    infoCell(title: "Puerta", value: trip.gate)
                    Spacer()
                    infoCell(title: "Asiento", value: trip.seat, highlight: true)
                }

                if trip.checkInDone && status != .cancelled {
                    VStack(spacing: 8) {
                        BoardingBarcode(code: trip.bookingCode)
                        Text("Pase de abordar listo · Abordas a las \(trip.boardingTimeText)")
                            .font(.caption)
                            .foregroundStyle(Theme.mint)
                    }
                } else if status != .cancelled {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Haz tu check-in para activar el pase de abordar")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(18)
        }
        .background(
            LinearGradient(colors: [Theme.horizon, Theme.dusk, Theme.night], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(alignment: .top) {
            // franja de color superior del pase
            Rectangle()
                .fill(Theme.sunsetGradient)
                .frame(height: 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var dashedDivider: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
            .padding(.horizontal, 12)
    }

    private func infoCell(title: String, value: String, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(highlight ? Font.title2.bold() : Font.subheadline.bold())
                .foregroundStyle(highlight ? Theme.sunset : .white)
        }
    }

    // MARK: Cuenta regresiva
    private func countdownText(now: Date) -> String {
        let seconds = Int(trip.departure.timeIntervalSince(now))
        if seconds <= 0 { return "Tu vuelo ya despegó" }
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days) d \(hours) h" }
        if hours > 0 { return "\(hours) h \(minutes) min" }
        return "\(minutes) min"
    }

    private func countdownCard(now: Date, status: TripStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(status == .inFlight || status == .completed ? "Estado" : "Despegue en")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                Text(status == .completed ? "Viaje completado" : countdownText(now: now))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Abordaje")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                Text(trip.boardingTimeText)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.mango)
            }
        }
        .aeroCard()
    }

    // MARK: Siguiente paso inteligente
    private func nextStep(status: TripStatus) -> (text: String, icon: String) {
        if status == .completed {
            return ("¡Llegaste! Que disfrutes \(trip.destinationCity).", "checkmark.seal.fill")
        }
        if status == .inFlight {
            return ("Disfruta tu vuelo. Aterrizas a las \(trip.arrival.hourText).", "airplane")
        }
        for item in trip.sortedChecklist where !item.isDone && status.rawValue >= item.requiredStatus {
            return ("Siguiente paso: \(item.title)", item.icon)
        }
        for item in trip.sortedChecklist where !item.isDone {
            return ("Pronto podrás: \(item.title.lowercased())", "clock.fill")
        }
        return ("Todo listo. Te esperamos en la puerta \(trip.gate) ✈︎", "checkmark.circle.fill")
    }

    private func nextStepCard(status: TripStatus) -> some View {
        let step = nextStep(status: status)
        return HStack(spacing: 12) {
            Image(systemName: step.icon)
                .font(.title3)
                .foregroundStyle(Theme.night)
                .frame(width: 42, height: 42)
                .background(Theme.sunsetGradient)
                .clipShape(Circle())
            Text(step.text)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .aeroCard()
    }

    // MARK: Checklist inteligente
    private func lockHint(for item: ChecklistItem) -> String {
        if item.requiredStatus == 1 { return "Se habilita 24 h antes del vuelo" }
        return "Se habilita 2 h antes del vuelo"
    }

    private func checklistCard(status: TripStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Checklist inteligente")
                        .font(.headline)
                    Text("\(trip.doneCount) de \(trip.checklist.count) tareas completadas")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                ProgressRing(progress: trip.progress)
            }

            if trip.progress >= 1 {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("¡Todo listo para despegar!")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Theme.mint)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Theme.mint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            ForEach(trip.sortedChecklist, id: \.order) { item in
                checklistRow(item, status: status)
            }
        }
        .aeroCard()
        .animation(.easeInOut, value: trip.doneCount)
    }

    private func checklistRow(_ item: ChecklistItem, status: TripStatus) -> some View {
        let locked = status.rawValue < item.requiredStatus && !item.isDone
        return Button {
            if locked { return }
            withAnimation(.spring) {
                item.isDone.toggle()
            }
            try? modelContext.save()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.isDone ? Theme.mint : Color.white.opacity(0.1))
                        .frame(width: 34, height: 34)
                    Image(systemName: item.isDone ? "checkmark" : (locked ? "lock.fill" : item.icon))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.isDone ? Theme.night : .white.opacity(0.8))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.bold())
                        .strikethrough(item.isDone, color: .white.opacity(0.5))
                        .foregroundStyle(item.isDone ? .white.opacity(0.5) : .white)
                    Text(locked ? lockHint(for: item) : item.detail)
                        .font(.caption)
                        .foregroundStyle(locked ? Theme.mango : .white.opacity(0.55))
                }
                Spacer()
            }
            .opacity(locked ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: Información del viaje
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalles del viaje")
                .font(.headline)
            detailRow("Reservación", trip.bookingCode)
            detailRow("Fecha", trip.departure.longDayText)
            detailRow("Equipaje", trip.baggage)
            detailRow("Aeronave", trip.aircraft)
            detailRow("Asiento", "\(trip.seat) · \(trip.seatNote)")
            detailRow("Vuelo", moneyText(trip.flightPrice, currency: trip.currency))
            detailRow("Asiento (cargo)", moneyText(trip.seatPrice, currency: trip.seatCurrency))
            detailRow("Origen de datos", trip.isLiveData ? "Duffel (en vivo)" : "Demostración")
        }
        .aeroCard()
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Simulador de tiempo (para la demostración)
    private var simulatorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Simulador de tiempo (demo)", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.mango)
            Text("Cambia la hora para ver cómo se desbloquean las tareas y cambia el estado del viaje.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
            Picker("Simulación", selection: $simulation) {
                ForEach(0..<scenarioNames.count, id: \.self) { index in
                    Text(scenarioNames[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
        .aeroCard()
    }

    // MARK: Cancelar
    private func cancelButton(status: TripStatus) -> some View {
        Group {
            if status != .completed && status != .inFlight {
                Button {
                    showCancelAlert = true
                } label: {
                    Label("Cancelar viaje", systemImage: "xmark.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.rose.opacity(0.8))
            }
        }
    }

    private var cancelledCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Theme.rose)
            Text("Este viaje fue cancelado y quedó guardado en tu historial.")
                .font(.subheadline)
        }
        .aeroCard()
    }
}
