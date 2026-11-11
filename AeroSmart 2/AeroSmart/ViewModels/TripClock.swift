//
//  TripClock.swift
//  AeroSmart
//

import Foundation
import Observation

// Reloj del viaje. Es el mismo patrón que la clase Counter de la clase 10:
// una Task que cada 30 segundos actualiza "now" y la vista se redibuja sola.
// Así el estado del viaje (Check-in abierto, Abordando, En vuelo...) cambia en vivo.
@MainActor
@Observable
final class TripClock {
    var now = Date()
    private var task: Task<Void, Never>?

    func start() {
        // evita arrancar dos relojes a la vez
        guard task == nil else { return }
        now = Date()
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                now = Date()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
