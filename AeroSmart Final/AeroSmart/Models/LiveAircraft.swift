import Foundation

struct LiveAircraft: Identifiable {
    let icao24: String
    let callsign: String
    let country: String
    let altitudeMeters: Double?
    let onGround: Bool
    let velocity: Double
    let heading: Double

    var id: String { icao24 }

    var altitudeText: String {
        guard let meters = altitudeMeters else { return "—" }
        return "\(Int(meters * 3.281)) ft"
    }

    var speedText: String {
        return "\(Int(velocity * 3.6)) km/h"
    }
}
