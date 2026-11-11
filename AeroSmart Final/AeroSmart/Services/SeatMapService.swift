import Foundation

struct SeatMapResult {
    let rows: [SeatRow]
    let isLive: Bool
    let notice: String?
}

private struct DuffelSeatMapsResponse: Decodable {
    let data: [SeatMap]

    struct SeatMap: Decodable {
        let cabins: [Cabin]
    }

    struct Cabin: Decodable {
        let rows: [Row]
        let wings: Wings?
    }

    struct Wings: Decodable {
        let firstRowIndex: Int?
        let lastRowIndex: Int?

        private enum CodingKeys: String, CodingKey {
            case firstRowIndex = "first_row_index"
            case lastRowIndex = "last_row_index"
        }
    }

    struct Row: Decodable {
        let sections: [Section]
    }

    struct Section: Decodable {
        let elements: [Element]
    }

    struct Element: Decodable {
        let type: String
        let designator: String?
        let disclosures: [String]?
        let availableServices: [Service]?

        private enum CodingKeys: String, CodingKey {
            case type, designator, disclosures
            case availableServices = "available_services"
        }
    }

    struct Service: Decodable {
        let totalAmount: String
        let totalCurrency: String

        private enum CodingKeys: String, CodingKey {
            case totalAmount = "total_amount"
            case totalCurrency = "total_currency"
        }
    }
}

enum SeatMapService {
    static func load(for flight: FlightOption) async -> SeatMapResult {
        var notice: String? = nil

        if flight.isLive, let offerId = flight.offerId {
            do {
                let rows = try await fetchDuffel(offerId: offerId, fallbackCurrency: flight.currency)
                if countSeats(in: rows) > 0 {
                    return SeatMapResult(rows: rows, isLive: true, notice: nil)
                }
                notice = "Esta aerolínea no ofrece selección de asiento en Duffel para esta oferta. Mostrando mapa de demostración."
            } catch {
                notice = "No se pudo cargar el mapa de Duffel (\(DuffelClient.describe(error))). Mostrando mapa de demostración."
            }
        }

        return SeatMapResult(rows: demoRows(seed: flight.id), isLive: false, notice: notice)
    }

    private static func countSeats(in rows: [SeatRow]) -> Int {
        var total = 0
        for row in rows {
            for section in row.sections {
                for slot in section.slots where slot.seat != nil {
                    total += 1
                }
            }
        }
        return total
    }

    private static func fetchDuffel(offerId: String, fallbackCurrency: String) async throws -> [SeatRow] {
        let data = try await DuffelClient.send(path: "/air/seat_maps?offer_id=\(offerId)")
        let response = try JSONDecoder().decode(DuffelSeatMapsResponse.self, from: data)

        guard let map = response.data.first else { return [] }
        return buildRows(from: map, fallbackCurrency: fallbackCurrency)
    }

    private static func buildRows(from map: DuffelSeatMapsResponse.SeatMap, fallbackCurrency: String) -> [SeatRow] {
        var totalRows = 0
        for cabin in map.cabins {
            totalRows += cabin.rows.count
        }

        var rows: [SeatRow] = []
        var globalIndex = 0

        for cabin in map.cabins {
            let wingStart = cabin.wings?.firstRowIndex ?? -1
            let wingEnd = cabin.wings?.lastRowIndex ?? -2

            for (rowIndex, row) in cabin.rows.enumerated() {
                let sectionCount = row.sections.count

                var isExit = false
                for section in row.sections {
                    for element in section.elements where element.type == "exit_row" {
                        isExit = true
                    }
                }

                let fraction = totalRows > 1 ? Double(globalIndex) / Double(totalRows - 1) : 0
                var label = ""
                var sections: [SeatSection] = []

                for (sectionIndex, section) in row.sections.enumerated() {
                    var seatPositions: [Int] = []
                    for (elementIndex, element) in section.elements.enumerated() where element.type == "seat" {
                        seatPositions.append(elementIndex)
                    }

                    var slots: [SeatSlot] = []
                    for (elementIndex, element) in section.elements.enumerated() {
                        if element.type == "seat" {
                            let services = element.availableServices ?? []
                            let available = !services.isEmpty
                            let price = Double(services.first?.totalAmount ?? "0") ?? 0
                            let currency = services.first?.totalCurrency ?? fallbackCurrency
                            let designator = element.designator ?? "?"
                            if label.isEmpty {
                                label = String(designator.prefix(while: { $0.isNumber }))
                            }

                            let isFirstSeat = (elementIndex == seatPositions.first)
                            let isLastSeat = (elementIndex == seatPositions.last)
                            let isWindow = (sectionIndex == 0 && isFirstSeat)
                                || (sectionIndex == sectionCount - 1 && isLastSeat)
                            let isAisle = (sectionIndex > 0 && isFirstSeat)
                                || (sectionIndex < sectionCount - 1 && isLastSeat)

                            let notes = (element.disclosures ?? []).joined(separator: " ").lowercased()
                            let legroom = isExit || notes.contains("legroom")

                            let seat = Seat(
                                designator: designator,
                                isAvailable: available,
                                price: price,
                                currency: currency,
                                isWindow: isWindow,
                                isAisle: isAisle,
                                hasExtraLegroom: legroom,
                                rowFraction: fraction
                            )
                            slots.append(SeatSlot(id: elementIndex, kind: .seat, seat: seat))
                        } else {
                            var kind = SeatKind.empty
                            if element.type == "lavatory" { kind = .lavatory }
                            if element.type == "galley" { kind = .galley }
                            slots.append(SeatSlot(id: elementIndex, kind: kind, seat: nil))
                        }
                    }
                    sections.append(SeatSection(id: sectionIndex, slots: slots))
                }

                let isWing = rowIndex >= wingStart && rowIndex <= wingEnd
                rows.append(SeatRow(id: globalIndex, label: label, sections: sections, isExitRow: isExit, isWingRow: isWing))
                globalIndex += 1
            }
        }

        return padRows(rows)
    }

    private static func padRows(_ rows: [SeatRow]) -> [SeatRow] {
        var maxCounts: [Int] = []
        for row in rows {
            for section in row.sections {
                if section.id < maxCounts.count {
                    maxCounts[section.id] = max(maxCounts[section.id], section.slots.count)
                } else {
                    maxCounts.append(section.slots.count)
                }
            }
        }

        var padded: [SeatRow] = []
        for row in rows {
            var newSections: [SeatSection] = []
            for section in row.sections {
                var slots = section.slots
                while slots.count < maxCounts[section.id] {
                    slots.append(SeatSlot(id: 1000 + slots.count, kind: .empty, seat: nil))
                }
                newSections.append(SeatSection(id: section.id, slots: slots))
            }
            padded.append(SeatRow(id: row.id, label: row.label, sections: newSections, isExitRow: row.isExitRow, isWingRow: row.isWingRow))
        }
        return padded
    }

    static func demoRows(seed key: String) -> [SeatRow] {
        var seed = 0
        for byte in key.utf8 {
            seed += Int(byte)
        }

        let letters = ["A", "B", "C", "D", "E", "F"]
        var rows: [SeatRow] = []

        for rowNumber in 1...30 {
            let isExit = (rowNumber == 12 || rowNumber == 13)
            var price = 150.0
            if rowNumber >= 2 && rowNumber <= 5 { price = 250 }
            if rowNumber == 1 { price = 350 }
            if isExit { price = 450 }
            let extraLegroom = isExit || rowNumber == 1
            let fraction = Double(rowNumber - 1) / 29.0

            var left: [SeatSlot] = []
            var right: [SeatSlot] = []
            for column in 0..<6 {
                let occupied = (seed + rowNumber * 37 + column * 53 + rowNumber * column * 11) % 100 < 42
                let seat = Seat(
                    designator: "\(rowNumber)\(letters[column])",
                    isAvailable: !occupied,
                    price: price,
                    currency: "MXN",
                    isWindow: column == 0 || column == 5,
                    isAisle: column == 2 || column == 3,
                    hasExtraLegroom: extraLegroom,
                    rowFraction: fraction
                )
                let slot = SeatSlot(id: column, kind: .seat, seat: seat)
                if column < 3 {
                    left.append(slot)
                } else {
                    right.append(slot)
                }
            }

            rows.append(
                SeatRow(
                    id: rowNumber,
                    label: "\(rowNumber)",
                    sections: [SeatSection(id: 0, slots: left), SeatSection(id: 1, slots: right)],
                    isExitRow: isExit,
                    isWingRow: rowNumber >= 10 && rowNumber <= 16
                )
            )
        }
        return rows
    }
}
