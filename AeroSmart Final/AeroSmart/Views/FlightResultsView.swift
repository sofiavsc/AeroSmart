import SwiftUI

struct FlightResultsView: View {
    let originCode: String
    let destinationCode: String
    let date: Date
    let user: User

    @State private var viewModel = FlightSearchViewModel()

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 14) {
                    routeHeader

                    if viewModel.isLoading {
                        AirplaneLoader(text: "Buscando los mejores vuelos…")
                            .padding(.top, 60)
                    } else {
                        if let notice = viewModel.notice {
                            NoticeBanner(text: notice)
                        } else if viewModel.isLive {
                            NoticeBanner(text: "Datos en vivo desde Duffel (modo prueba).", isLive: true)
                        }

                        if viewModel.flights.isEmpty {
                            emptyState
                        } else {
                            sortPicker
                            ForEach(viewModel.sortedFlights, id: \.id) { flight in
                                NavigationLink {
                                    SeatSelectionView(flight: flight, user: user)
                                } label: {
                                    FlightCardView(flight: flight, badges: viewModel.badges(for: flight))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Vuelos disponibles")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(origin: originCode, destination: destinationCode, date: date)
        }
    }

    private var routeHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(originCode)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text(Airport.cityName(originCode))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundStyle(Theme.sunset)
                Text(date.shortDayText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(destinationCode)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text(Airport.cityName(destinationCode))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .aeroCard()
    }

    private var sortPicker: some View {
        Picker("Ordenar por", selection: $viewModel.sort) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 42))
                .foregroundStyle(Theme.sunset)
            Text("No hay vuelos disponibles")
                .font(.headline)
            Text("Prueba con otra fecha u otro destino.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 50)
    }
}
