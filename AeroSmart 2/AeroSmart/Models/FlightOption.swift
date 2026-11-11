//
//  FlightOption.swift
//  AeroSmart
//

import Foundation

// Un vuelo encontrado en la búsqueda (no se guarda en SwiftData hasta reservar).
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
    // Id de la oferta en Duffel (solo cuando el vuelo viene de la API real)
    let offerId: String?
    let isLive: Bool
}
