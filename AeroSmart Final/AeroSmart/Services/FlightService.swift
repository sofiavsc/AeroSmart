import Foundation

struct FlightSearchOutcome {
    let flights: [FlightOption]
    let isLive: Bool
    let notice: String?
}

private struct DuffelOfferRequestResponse: Decodable {
    let data: Payload

    struct Payload: Decodable {
        let offers: [Offer]?
    }

    struct Offer: Decodable {
        let id: String
        let totalAmount: String
        let totalCurrency: String
        let owner: Company?
        let slices: [Slice]

        private enum CodingKeys: String, CodingKey {
            case id, owner, slices
            case totalAmount = "total_amount"
            case totalCurrency = "total_currency"
        }
    }

    struct Company: Decodable {
        let name: String?
        let iataCode: String?

        private enum CodingKeys: String, CodingKey {
            case name
            case iataCode = "iata_code"
        }
    }

    struct Slice: Decodable {
        let duration: String?
        let segments: [Segment]
    }

    struct Segment: Decodable {
        let departingAt: String
        let arrivingAt: String
        let marketingCarrierFlightNumber: String?
        let marketingCarrier: Company?
        let aircraft: Aircraft?
        let originTerminal: String?

        private enum CodingKeys: String, CodingKey {
            case aircraft
            case departingAt = "departing_at"
            case arrivingAt = "arriving_at"
            case marketingCarrierFlightNumber = "marketing_carrier_flight_number"
            case marketingCarrier = "marketing_carrier"
            case originTerminal = "origin_terminal"
        }
    }

    struct Aircraft: Decodable {
        let name: String?
    }
}

enum FlightService {
    static func search(origin: String, destination: String, date: Date) async -> FlightSearchOutcome {
        if DuffelClient.hasToken {
            do {
                let live = try await searchDuffel(origin: origin, destination: destination, date: date)
                if !live.isEmpty {
                    return FlightSearchOutcome(flights: live, isLive: true, notice: nil)
                }
                return FlightSearchOutcome(
                    flights: demoFlights(origin: origin, destination: destination, date: date),
                    isLive: false,
                    notice: "Duffel no devolvió vuelos para esta ruta y fecha. Mostrando vuelos de demostración."
                )
            } catch {
                return FlightSearchOutcome(
                    flights: demoFlights(origin: origin, destination: destination, date: date),
                    isLive: false,
                    notice: "No se pudo consultar Duffel (\(DuffelClient.describe(error))). Mostrando vuelos de demostración."
                )
            }
        }
        return FlightSearchOutcome(
            flights: demoFlights(origin: origin, destination: destination, date: date),
            isLive: false,
            notice: "Modo demostración. Agrega tu token de Duffel en Perfil para ver vuelos en vivo."
        )
    }

    private static func searchDuffel(origin: String, destination: String, date: Date) async throws -> [FlightOption] {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let slice: [String: Any] = [
            "origin": origin,
            "destination": destination,
            "departure_date": dayFormatter.string(from: date)
        ]
        let payload: [String: Any] = [
            "slices": [slice],
            "passengers": [["type": "adult"]],
            "cabin_class": "economy"
        ]
        let body: [String: Any] = ["data": payload]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let data = try await DuffelClient.send(
            path: "/air/offer_requests?return_offers=true",
            method: "POST",
            body: bodyData
        )

        let response = try JSONDecoder().decode(DuffelOfferRequestResponse.self, from: data)

        var flights: [FlightOption] = []
        let offers = response.data.offers ?? []
        for offer in offers {
            guard let firstSlice = offer.slices.first,
                  let firstSegment = firstSlice.segments.first,
                  let lastSegment = firstSlice.segments.last,
                  let departure = parseDuffelDate(firstSegment.departingAt),
                  let arrival = parseDuffelDate(lastSegment.arrivingAt)
            else { continue }

            let carrierCode = firstSegment.marketingCarrier?.iataCode ?? ""
            let number = firstSegment.marketingCarrierFlightNumber ?? ""
            var flightNumber = (carrierCode + " " + number).trimmingCharacters(in: .whitespaces)
            if flightNumber.isEmpty { flightNumber = "Vuelo" }

            let fallbackMinutes = max(Int(arrival.timeIntervalSince(departure) / 60), 30)
            let minutes = minutesFromISODuration(firstSlice.duration ?? "") ?? fallbackMinutes

            let flight = FlightOption(
                id: offer.id,
                airline: offer.owner?.name ?? firstSegment.marketingCarrier?.name ?? "Aerolínea",
                flightNumber: flightNumber,
                originCode: origin,
                destinationCode: destination,
                departure: departure,
                arrival: arrival,
                durationMinutes: minutes,
                price: Double(offer.totalAmount) ?? 0,
                currency: offer.totalCurrency,
                aircraft: firstSegment.aircraft?.name ?? "Aeronave",
                terminal: firstSegment.originTerminal ?? terminal(for: flightNumber),
                gate: gate(for: flightNumber),
                offerId: offer.id,
                isLive: true
            )
            flights.append(flight)
            if flights.count >= 15 { break }
        }
        return flights
    }

    private static func parseDuffelDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: text) { return date }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = formatter.date(from: text) { return date }
        return ISO8601DateFormatter().date(from: text)
    }

    static func demoFlights(origin: String, destination: String, date: Date) -> [FlightOption] {
        guard let from = Airport.find(origin), let to = Airport.find(destination) else { return [] }

        let km = Airport.distanceKm(from, to)
        let minutes = Int(km / 760 * 60) + 45
        let slots: [(hour: Int, minute: Int)] = [(6, 30), (9, 50), (13, 15), (16, 40), (20, 5)]
        let priceFactors: [Double] = [0.90, 1.00, 1.10, 1.25, 0.95]

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyyMMdd"
        let dayKey = dayFormatter.string(from: date)

        var result: [FlightOption] = []
        for (index, slot) in slots.enumerated() {
            guard let departure = calendar.date(bySettingHour: slot.hour, minute: slot.minute, second: 0, of: day) else { continue }
            if departure <= Date() { continue }

            let arrival = departure.addingTimeInterval(Double(minutes) * 60)
            let number = 100 + (Int(km) % 600) + index * 17
            let flightNumber = "AS \(number)"
            let rawPrice = (650 + km * 1.05) * priceFactors[index]
            let price = (rawPrice / 10).rounded() * 10

            let flight = FlightOption(
                id: "DEMO-\(origin)-\(destination)-\(number)-\(dayKey)",
                airline: "AeroSmart Air",
                flightNumber: flightNumber,
                originCode: origin,
                destinationCode: destination,
                departure: departure,
                arrival: arrival,
                durationMinutes: minutes,
                price: price,
                currency: "MXN",
                aircraft: "Airbus A320",
                terminal: terminal(for: flightNumber),
                gate: gate(for: flightNumber),
                offerId: nil,
                isLive: false
            )
            result.append(flight)
        }
        return result
    }

    private static func checksum(_ text: String) -> Int {
        var sum = 0
        for byte in text.utf8 {
            sum += Int(byte)
        }
        return sum
    }

    static func terminal(for flightNumber: String) -> String {
        return checksum(flightNumber) % 2 == 0 ? "1" : "2"
    }

    static func gate(for flightNumber: String) -> String {
        let letters = ["A", "B", "C", "D"]
        let sum = checksum(flightNumber)
        return "\(letters[sum % 4])\(1 + sum % 12)"
    }
}
