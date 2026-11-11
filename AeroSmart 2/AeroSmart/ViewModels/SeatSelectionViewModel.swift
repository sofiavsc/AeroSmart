//
//  SeatSelectionViewModel.swift
//  AeroSmart
//

import Foundation
import Observation

@MainActor
@Observable
final class SeatSelectionViewModel {
    var rows: [SeatRow] = []
    var isLoading = true
    var isLive = false
    var notice: String? = nil
    var selectedDesignator: String? = nil
    var preferences: Set<SeatPreference> = []
    var recommendedDesignator: String? = nil

    private var hasLoaded = false

    func load(flight: FlightOption) async {
        if hasLoaded { return }
        hasLoaded = true
        isLoading = true
        let result = await SeatMapService.load(for: flight)
        rows = result.rows
        isLive = result.isLive
        notice = result.notice
        isLoading = false
    }

    var allSeats: [Seat] {
        var result: [Seat] = []
        for row in rows {
            for section in row.sections {
                for slot in section.slots {
                    if let seat = slot.seat {
                        result.append(seat)
                    }
                }
            }
        }
        return result
    }

    var selectedSeat: Seat? {
        guard let designator = selectedDesignator else { return nil }
        for seat in allSeats where seat.designator == designator {
            return seat
        }
        return nil
    }

    var recommendedSeat: Seat? {
        guard let designator = recommendedDesignator else { return nil }
        for seat in allSeats where seat.designator == designator {
            return seat
        }
        return nil
    }

    var availableCount: Int {
        var count = 0
        for seat in allSeats where seat.isAvailable {
            count += 1
        }
        return count
    }

    func select(_ seat: Seat) {
        if !seat.isAvailable { return }
        if selectedDesignator == seat.designator {
            selectedDesignator = nil
        } else {
            selectedDesignator = seat.designator
        }
    }

    func togglePreference(_ preference: SeatPreference) {
        if preferences.contains(preference) {
            preferences.remove(preference)
        } else {
            preferences.insert(preference)
        }
        recomputeRecommendation()
    }

    // Asistente inteligente: califica cada asiento libre según tus preferencias.
    func recomputeRecommendation() {
        if preferences.isEmpty {
            recommendedDesignator = nil
            return
        }

        var best: Seat? = nil
        var bestScore = -1.0
        for seat in allSeats where seat.isAvailable {
            let value = score(seat)
            if best == nil || value > bestScore {
                best = seat
                bestScore = value
            } else if value == bestScore, let current = best, seat.price < current.price {
                best = seat
            }
        }
        recommendedDesignator = best?.designator
    }

    private func score(_ seat: Seat) -> Double {
        var total = 0.0
        if preferences.contains(.window) && seat.isWindow { total += 3 }
        if preferences.contains(.aisle) && seat.isAisle { total += 3 }
        if preferences.contains(.legroom) && seat.hasExtraLegroom { total += 3 }
        if preferences.contains(.front) { total += 3 * (1 - seat.rowFraction) }
        if preferences.contains(.cheap) {
            if seat.price == 0 {
                total += 3
            } else {
                total += max(0, 3 - seat.price / 150)
            }
        }
        return total
    }
}
