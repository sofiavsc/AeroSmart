import SwiftUI

struct FlightCardView: View {
    let flight: FlightOption
    var badges: [String] = []

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Text(flight.airline)
                    .font(.subheadline.bold())
                Text(flight.flightNumber)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                ForEach(badges, id: \.self) { badge in
                    StatusPill(text: badge, color: badgeColor(badge))
                }
            }

            HStack {
                timeColumn(time: flight.departure.hourText, code: flight.originCode, alignment: .leading)
                Spacer()
                VStack(spacing: 4) {
                    Text(durationText(flight.durationMinutes))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 2)
                        Image(systemName: "airplane")
                            .foregroundStyle(Theme.sunset)
                    }
                }
                .frame(maxWidth: 120)
                Spacer()
                timeColumn(time: flight.arrival.hourText, code: flight.destinationCode, alignment: .trailing)
            }

            HStack {
                Text(flight.departure.shortDayText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(moneyText(flight.price, currency: flight.currency))
                    .font(.title3.bold())
                    .foregroundStyle(Theme.sunset)
            }
        }
        .aeroCard()
    }

    private func timeColumn(time: String, code: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(time)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(code)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func badgeColor(_ badge: String) -> Color {
        if badge == "Mejor opción" { return Theme.mint }
        if badge == "Más barato" { return Theme.mango }
        return Theme.lilac
    }
}
