import Foundation
import SwiftUI

struct DeparturesResponse: Decodable {
    let data: [FlightStatus]
}

struct FlightStatus: Decodable {
    let flightStatus: String?
    let departure: Endpoint
    let arrival: Endpoint
    let airline: Airline?
    let flight: FlightNumber?

    private enum CodingKeys: String, CodingKey {
        case departure, arrival, airline, flight
        case flightStatus = "flight_status"
    }

    struct Endpoint: Decodable {
        let airport: String?
        let iata: String?
        let terminal: String?
        let gate: String?
        let delay: Int?
        let scheduled: String?
    }

    struct Airline: Decodable {
        let name: String?
    }

    struct FlightNumber: Decodable {
        let iata: String?
    }
}

extension FlightStatus {
    var flightNumberText: String {
        return flight?.iata ?? "—"
    }

    var departureTime: String {
        guard let text = departure.scheduled, text.count >= 16 else { return "--:--" }
        return String(text.dropFirst(11).prefix(5))
    }

    var destinationText: String {
        let city = Airport.find(arrival.iata ?? "")?.city ?? arrival.airport ?? "Destino"
        return "\(city) (\(arrival.iata ?? "?"))"
    }

    var statusTitle: String {
        if let delay = departure.delay, delay > 0, flightStatus == "scheduled" {
            return "Retraso \(delay) min"
        }
        switch flightStatus {
        case "scheduled": return "A tiempo"
        case "active": return "En vuelo"
        case "landed": return "Aterrizó"
        case "cancelled": return "Cancelado"
        case "diverted": return "Desviado"
        case "incident": return "Incidente"
        default: return "Sin info"
        }
    }

    var statusColor: Color {
        if let delay = departure.delay, delay > 0, flightStatus == "scheduled" {
            return Theme.mango
        }
        switch flightStatus {
        case "scheduled": return Theme.lilac
        case "active": return Theme.mint
        case "cancelled", "incident": return Theme.rose
        case "diverted": return Theme.mango
        default: return Color.gray
        }
    }
}
