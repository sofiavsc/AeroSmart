import Foundation

struct FlightOption {
    let id: String
    let airline: String
    let flightNumber: String
    let originCode: String
    let destinationCode: String
    let departure: Date
    let arrival: Date
    let durationMinutes: Int
    let price: Double
    let currency: String
    let aircraft: String
    let terminal: String
    let gate: String
    let offerId: String?
    let isLive: Bool
}
