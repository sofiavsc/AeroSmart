//
//  SeatMapView.swift
//  AeroSmart
//

import SwiftUI

// MARK: - Mapa completo del avión
struct SeatMapView: View {
    let rows: [SeatRow]
    let selectedDesignator: String?
    let recommendedDesignator: String?
    let onSelect: (Seat) -> Void

    // Tamaño de cada asiento según cuántas columnas tenga el avión.
    private var cellSize: CGFloat {
        var maxSlots = 0
        for row in rows {
            var count = 0
            for section in row.sections {
                count += section.slots.count
            }
            if count > maxSlots { maxSlots = count }
        }
        if maxSlots <= 7 { return 34 }
        if maxSlots <= 10 { return 28 }
        return 23
    }

    var body: some View {
        VStack(spacing: 8) {
            nose

            ForEach(rows, id: \.id) { row in
                SeatRowView(
                    row: row,
                    cellSize: cellSize,
                    selectedDesignator: selectedDesignator,
                    recommendedDesignator: recommendedDesignator,
                    onSelect: onSelect
                )
            }

            Text("Cola del avión")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.top, 8)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 60)
                .fill(.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var nose: some View {
        VStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.title2)
                .rotationEffect(.degrees(-90))
                .foregroundStyle(Theme.sunset.opacity(0.7))
            Text("Cabina")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.top, 36)
        .padding(.bottom, 14)
    }
}

// MARK: - Una fila de asientos
struct SeatRowView: View {
    let row: SeatRow
    let cellSize: CGFloat
    let selectedDesignator: String?
    let recommendedDesignator: String?
    let onSelect: (Seat) -> Void

    var body: some View {
        HStack(spacing: 6) {
            exitMarker

            Text(row.label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 20)

            ForEach(row.sections, id: \.id) { section in
                HStack(spacing: 6) {
                    ForEach(section.slots, id: \.id) { slot in
                        slotView(slot)
                    }
                }
                if section.id < row.sections.count - 1 {
                    Color.clear.frame(width: 14, height: 1)
                }
            }

            exitMarker
        }
        .padding(.vertical, 1)
        .background(row.isWingRow ? Color.white.opacity(0.04) : Color.clear)
    }

    private var exitMarker: some View {
        Group {
            if row.isExitRow {
                Image(systemName: "door.left.hand.open")
                    .font(.caption2)
                    .foregroundStyle(Theme.mango)
            } else {
                Color.clear
            }
        }
        .frame(width: 16)
    }

    @ViewBuilder
    private func slotView(_ slot: SeatSlot) -> some View {
        if let seat = slot.seat {
            SeatCellView(
                seat: seat,
                size: cellSize,
                isSelected: seat.designator == selectedDesignator,
                isRecommended: seat.designator == recommendedDesignator
            ) {
                onSelect(seat)
            }
        } else if slot.kind == .lavatory || slot.kind == .galley {
            Image(systemName: slot.kind == .lavatory ? "toilet.fill" : "cup.and.saucer.fill")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: cellSize, height: cellSize)
        } else {
            Color.clear.frame(width: cellSize, height: cellSize)
        }
    }
}

// MARK: - Un asiento
struct SeatCellView: View {
    let seat: Seat
    let size: CGFloat
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    @State private var pulse = false

    private var baseColor: Color {
        if !seat.isAvailable { return Color.white.opacity(0.06) }
        if seat.hasExtraLegroom { return Theme.mango.opacity(0.28) }
        return Color.white.opacity(0.16)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(baseColor)

                if isSelected {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.sunsetGradient)
                }

                if isRecommended && !isSelected {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Theme.mint, lineWidth: 2)
                        .scaleEffect(pulse ? 1.45 : 1.0)
                        .opacity(pulse ? 0 : 1)
                }

                if seat.isAvailable {
                    Text(seat.letter)
                        .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Theme.night : .white.opacity(0.9))
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.3, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isSelected ? 1.12 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(!seat.isAvailable)
        .onAppear {
            startPulse()
        }
        .onChange(of: isRecommended) {
            startPulse()
        }
    }

    // Solo el asiento recomendado anima el aro (así los demás no gastan recursos).
    private func startPulse() {
        if isRecommended {
            if !pulse {
                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
        } else {
            pulse = false
        }
    }
}
