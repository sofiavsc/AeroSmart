import SwiftUI

struct LiveView: View {
    @AppStorage("lastOrigin") private var airportCode = "TAM"

    @State private var mode = 0
    @State private var departures = DeparturesViewModel()
    @State private var radar = RadarViewModel()

    private var airport: Airport? {
        return Airport.find(airportCode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        Picker("Vista", selection: $mode) {
                            Text("Salidas de hoy").tag(0)
                            Text("Radar").tag(1)
                        }
                        .pickerStyle(.segmented)

                        if mode == 0 {
                            departuresSection
                        } else {
                            radarSection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("En vivo")
            .task {
                await loadIfNeeded()
            }
            .onChange(of: airportCode) {
                Task {
                    await loadIfNeeded()
                }
            }
            .onChange(of: mode) {
                Task {
                    await loadIfNeeded()
                }
            }
        }
    }

    private func loadIfNeeded() async {
        if mode == 0 && departures.loadedCode != airportCode {
            await departures.getDepartures(from: airportCode)
        }
        if mode == 1 && radar.loadedCode != airportCode, let airport = airport {
            await radar.getAircraft(near: airport)
        }
    }

    private func reload() async {
        if mode == 0 {
            await departures.getDepartures(from: airportCode)
        } else if let airport = airport {
            await radar.getAircraft(near: airport)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(airportCode)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                Text(airport?.name ?? "")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Picker("Aeropuerto", selection: $airportCode) {
                    ForEach(Airport.all, id: \.code) { airport in
                        Text("\(airport.city) (\(airport.code))").tag(airport.code)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Theme.mango)

                Button {
                    Task {
                        await reload()
                    }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.dusk)
            }
        }
        .aeroCard()
    }

    @ViewBuilder
    private var departuresSection: some View {
        if departures.isLoading {
            AirplaneLoader(text: "Consultando el tablero de salidas…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let message = departures.errorMessage {
            NoticeBanner(text: message)
        } else if departures.flights.isEmpty {
            NoticeBanner(text: "No hay salidas registradas para \(airportCode) en este momento.")
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("HORA").frame(width: 52, alignment: .leading)
                    Text("VUELO").frame(width: 70, alignment: .leading)
                    Text("DESTINO")
                    Spacer()
                    Text("ESTATUS")
                }
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 10)

                ForEach(0..<departures.flights.count, id: \.self) { index in
                    departureRow(departures.flights[index])
                    if index < departures.flights.count - 1 {
                        Divider().background(.white.opacity(0.15))
                    }
                }
            }
            .aeroCard()

            Text("Datos de Aviationstack · horario local del aeropuerto")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private func departureRow(_ flight: FlightStatus) -> some View {
        HStack(alignment: .center) {
            Text(flight.departureTime)
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(Theme.mango)
                .frame(width: 52, alignment: .leading)

            Text(flight.flightNumberText)
                .font(.system(.caption, design: .monospaced).bold())
                .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(flight.destinationText)
                    .font(.caption.bold())
                    .lineLimit(1)
                if let gate = flight.departure.gate {
                    Text("Puerta \(gate)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            Spacer()

            StatusPill(text: flight.statusTitle, color: flight.statusColor)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var radarSection: some View {
        if radar.isLoading {
            AirplaneLoader(text: "Buscando aviones en el cielo…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let message = radar.errorMessage {
            NoticeBanner(text: message)
        } else if radar.aircraft.isEmpty {
            NoticeBanner(text: "No hay aviones transmitiendo cerca de \(airportCode) ahorita. Prueba con MEX o CUN.")
        } else {
            HStack {
                Label("\(radar.aircraft.count) aviones cerca de \(airport?.city ?? airportCode)", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.mint)
                Spacer()
            }

            ForEach(radar.aircraft) { plane in
                aircraftRow(plane)
            }

            Text("Datos de OpenSky Network · se actualizan cada vez que tocas Actualizar")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private func aircraftRow(_ plane: LiveAircraft) -> some View {
        HStack(spacing: 14) {
            Image(systemName: plane.onGround ? "airplane.arrival" : "airplane")
                .font(.title2)
                .foregroundStyle(plane.onGround ? Color.white.opacity(0.5) : Theme.mango)
                .rotationEffect(.degrees(plane.onGround ? 0 : plane.heading - 90))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(plane.callsign)
                    .font(.system(.headline, design: .monospaced))
                Text(plane.country)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if plane.onGround {
                    StatusPill(text: "En tierra", color: .gray)
                } else {
                    Text(plane.altitudeText)
                        .font(.subheadline.bold())
                    Text(plane.speedText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .aeroCard()
    }
}
