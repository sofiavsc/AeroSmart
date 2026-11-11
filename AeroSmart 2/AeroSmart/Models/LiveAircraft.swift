//
//  LiveAircraft.swift
//  AeroSmart
//

import Foundation

// Un avión que está en el aire ahora mismo (viene de OpenSky Network)
struct LiveAircraft: Identifiable {
    let icao24: String          // dirección única del transpondedor, sirve como id
    let callsign: String        // por ejemplo "VOI1234"
    let country: String         // país donde está registrado
    let altitudeMeters: Double?
    let onGround: Bool
    let velocity: Double        // metros por segundo
    let heading: Double         // 0 = norte, 90 = este

    var id: String { icao24 }

    var altitudeText: String {
        guard let meters = altitudeMeters else { return "—" }
        // en aviación la altura se dice en pies
        return "\(Int(meters * 3.281)) ft"
    }

    var speedText: String {
        return "\(Int(velocity * 3.6)) km/h"
    }
}
