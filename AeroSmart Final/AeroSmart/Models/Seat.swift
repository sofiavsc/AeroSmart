import Foundation

enum SeatKind {
    case seat
    case empty
    case lavatory
    case galley
}

struct Seat {
    let designator: String
    let isAvailable: Bool
    let price: Double
    let currency: String
    let isWindow: Bool
    let isAisle: Bool
    let hasExtraLegroom: Bool
    let rowFraction: Double

    var letter: String {
        return String(designator.suffix(1))
    }

    var traits: String {
        var parts: [String] = []
        if isWindow { parts.append("Ventana") }
        if isAisle { parts.append("Pasillo") }
        if !isWindow && !isAisle { parts.append("Centro") }
        if hasExtraLegroom { parts.append("Más espacio") }
        return parts.joined(separator: " · ")
    }
}

struct SeatSlot {
    let id: Int
    let kind: SeatKind
    let seat: Seat?
}

struct SeatSection {
    let id: Int
    let slots: [SeatSlot]
}

struct SeatRow {
    let id: Int
    let label: String
    let sections: [SeatSection]
    let isExitRow: Bool
    let isWingRow: Bool
}

enum SeatPreference: String, CaseIterable {
    case window = "Ventana"
    case aisle = "Pasillo"
    case legroom = "Más espacio"
    case front = "Salir rápido"
    case cheap = "Económico"

    var icon: String {
        switch self {
        case .window: return "window.vertical.open"
        case .aisle: return "figure.walk"
        case .legroom: return "arrow.up.and.down"
        case .front: return "bolt.fill"
        case .cheap: return "tag.fill"
        }
    }
}
