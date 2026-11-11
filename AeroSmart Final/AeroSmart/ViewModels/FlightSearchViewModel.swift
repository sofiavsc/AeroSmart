import Foundation
import Observation

enum SortOption: String, CaseIterable {
    case price = "Precio"
    case duration = "Duración"
    case departure = "Salida"
}

@MainActor
@Observable
final class FlightSearchViewModel {
    var flights: [FlightOption] = []
    var isLoading = true
    var isLive = false
    var notice: String? = nil
    var sort: SortOption = .price

    private var hasLoaded = false

    func load(origin: String, destination: String, date: Date) async {
        if hasLoaded { return }
        hasLoaded = true
        isLoading = true
        let outcome = await FlightService.search(origin: origin, destination: destination, date: date)
        flights = outcome.flights
        isLive = outcome.isLive
        notice = outcome.notice
        isLoading = false
    }

    var sortedFlights: [FlightOption] {
        switch sort {
        case .price:
            return flights.sorted { $0.price < $1.price }
        case .duration:
            return flights.sorted { $0.durationMinutes < $1.durationMinutes }
        case .departure:
            return flights.sorted { $0.departure < $1.departure }
        }
    }

    var cheapestId: String? {
        return flights.min { $0.price < $1.price }?.id
    }

    var fastestId: String? {
        return flights.min { $0.durationMinutes < $1.durationMinutes }?.id
    }

    var bestId: String? {
        guard flights.count > 1,
              let minPrice = flights.map({ $0.price }).min(),
              let minDuration = flights.map({ $0.durationMinutes }).min(),
              minPrice > 0, minDuration > 0
        else { return nil }

        func score(_ flight: FlightOption) -> Double {
            return flight.price / minPrice + Double(flight.durationMinutes) / Double(minDuration)
        }
        return flights.min { score($0) < score($1) }?.id
    }

    func badges(for flight: FlightOption) -> [String] {
        var result: [String] = []
        if flight.id == bestId { result.append("Mejor opción") }
        if flight.id == cheapestId { result.append("Más barato") }
        if flight.id == fastestId { result.append("Más rápido") }
        return result
    }
}
