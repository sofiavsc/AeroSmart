import Foundation
import SwiftData
import SwiftUI

enum TripStatus: Int {
    case scheduled = 0
    case checkInOpen = 1
    case boardingSoon = 2
    case boarding = 3
    case inFlight = 4
    case completed = 5
    case cancelled = 6

    var title: String {
        switch self {
        case .scheduled: return "Programado"
        case .checkInOpen: return "Check-in abierto"
        case .boardingSoon: return "Ve al aeropuerto"
        case .boarding: return "Abordando"
        case .inFlight: return "En vuelo"
        case .completed: return "Completado"
        case .cancelled: return "Cancelado"
        }
    }

    var color: Color {
        switch self {
        case .scheduled: return Theme.lilac
        case .checkInOpen: return Theme.mint
        case .boardingSoon: return Theme.mango
        case .boarding: return Theme.rose
        case .inFlight: return Theme.sunset
        case .completed: return Color.gray
        case .cancelled: return Theme.rose
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .checkInOpen: return "qrcode.viewfinder"
        case .boardingSoon: return "figure.walk"
        case .boarding: return "door.left.hand.open"
        case .inFlight: return "airplane"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

@Model
final class Trip {
    var ownerEmail: String
    var airline: String
    var flightNumber: String
    var originCode: String
    var destinationCode: String
    var departure: Date
    var arrival: Date
    var durationMinutes: Int
    var terminal: String
    var gate: String
    var seat: String
    var seatNote: String
    var flightPrice: Double
    var seatPrice: Double
    var currency: String
    var seatCurrency: String
    var aircraft: String
    var baggage: String
    var bookingCode: String
    var isLiveData: Bool
    var isCancelled: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.trip)
    var checklist: [ChecklistItem] = []

    init(
        ownerEmail: String,
        airline: String,
        flightNumber: String,
        originCode: String,
        destinationCode: String,
        departure: Date,
        arrival: Date,
        durationMinutes: Int,
        terminal: String,
        gate: String,
        seat: String,
        seatNote: String,
        flightPrice: Double,
        seatPrice: Double,
        currency: String,
        seatCurrency: String,
        aircraft: String,
        bookingCode: String,
        isLiveData: Bool
    ) {
        self.ownerEmail = ownerEmail
        self.airline = airline
        self.flightNumber = flightNumber
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.departure = departure
        self.arrival = arrival
        self.durationMinutes = durationMinutes
        self.terminal = terminal
        self.gate = gate
        self.seat = seat
        self.seatNote = seatNote
        self.flightPrice = flightPrice
        self.seatPrice = seatPrice
        self.currency = currency
        self.seatCurrency = seatCurrency
        self.aircraft = aircraft
        self.baggage = "1 artículo personal + 1 maleta de mano (10 kg)"
        self.bookingCode = bookingCode
        self.isLiveData = isLiveData
        self.isCancelled = false
        self.createdAt = Date()
    }
}

extension Trip {
    var originCity: String {
        Airport.cityName(originCode)
    }

    var destinationCity: String {
        Airport.cityName(destinationCode)
    }

    var sortedChecklist: [ChecklistItem] {
        checklist.sorted { $0.order < $1.order }
    }

    var progress: Double {
        if checklist.isEmpty { return 0 }
        return Double(doneCount) / Double(checklist.count)
    }

    var doneCount: Int {
        var done = 0
        for item in checklist where item.isDone {
            done += 1
        }
        return done
    }

    var checkInDone: Bool {
        for item in checklist where item.order == 1 {
            return item.isDone
        }
        return false
    }

    var boardingTimeText: String {
        departure.addingTimeInterval(-40 * 60).hourText
    }

    func status(at now: Date) -> TripStatus {
        if isCancelled { return .cancelled }
        if now >= arrival { return .completed }
        if now >= departure { return .inFlight }
        let untilDeparture = departure.timeIntervalSince(now)
        if untilDeparture <= 40 * 60 { return .boarding }
        if untilDeparture <= 2 * 3600 { return .boardingSoon }
        if untilDeparture <= 24 * 3600 { return .checkInOpen }
        return .scheduled
    }

    static func make(flight: FlightOption, seat: Seat, ownerEmail: String, isLiveSeatMap: Bool) -> Trip {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
        var code = ""
        for _ in 0..<6 {
            code.append(letters.randomElement() ?? "A")
        }
        return Trip(
            ownerEmail: ownerEmail,
            airline: flight.airline,
            flightNumber: flight.flightNumber,
            originCode: flight.originCode,
            destinationCode: flight.destinationCode,
            departure: flight.departure,
            arrival: flight.arrival,
            durationMinutes: flight.durationMinutes,
            terminal: flight.terminal,
            gate: flight.gate,
            seat: seat.designator,
            seatNote: seat.traits,
            flightPrice: flight.price,
            seatPrice: seat.price,
            currency: flight.currency,
            seatCurrency: seat.currency,
            aircraft: flight.aircraft,
            bookingCode: code,
            isLiveData: flight.isLive && isLiveSeatMap
        )
    }

    func buildChecklist() -> [ChecklistItem] {
        let airportName = Airport.find(originCode)?.name ?? originCode
        return [
            ChecklistItem(title: "Seleccionar asiento", detail: "Asiento \(seat) · \(seatNote)", icon: "airplane.circle.fill", order: 0, isDone: true, requiredStatus: 0),
            ChecklistItem(title: "Realizar check-in", detail: "Activa tu pase de abordar", icon: "qrcode.viewfinder", order: 1, isDone: false, requiredStatus: 1),
            ChecklistItem(title: "Revisar documentación", detail: "Identificación oficial o pasaporte vigente", icon: "doc.text.magnifyingglass", order: 2, isDone: false, requiredStatus: 0),
            ChecklistItem(title: "Preparar equipaje", detail: baggage, icon: "suitcase.fill", order: 3, isDone: false, requiredStatus: 0),
            ChecklistItem(title: "Consultar información del aeropuerto", detail: "Terminal \(terminal) · \(airportName)", icon: "building.columns.fill", order: 4, isDone: false, requiredStatus: 0),
            ChecklistItem(title: "Revisar horario y puerta de abordaje", detail: "Puerta \(gate) · Abordaje a las \(boardingTimeText)", icon: "door.left.hand.open", order: 5, isDone: false, requiredStatus: 2)
        ]
    }
}
