import SwiftUI

enum Theme {
    static let night = Color(red: 0.043, green: 0.078, blue: 0.149)
    static let dusk = Color(red: 0.07, green: 0.11, blue: 0.30)
    static let horizon = Color(red: 0.22, green: 0.14, blue: 0.42)
    static let sunset = Color(red: 1.00, green: 0.46, blue: 0.38)
    static let mango = Color(red: 1.00, green: 0.73, blue: 0.30)
    static let lilac = Color(red: 0.72, green: 0.58, blue: 1.00)
    static let rose = Color(red: 1.00, green: 0.34, blue: 0.52)
    static let mint = Color(red: 0.42, green: 0.92, blue: 0.70)
    static let card = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.14)

    static let sunsetGradient = LinearGradient(
        colors: [sunset, mango],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct AeroBackground: View {
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-150, -360, 2), (-60, -330, 3), (40, -380, 2), (130, -340, 2),
        (170, -260, 3), (-170, -250, 2), (-90, -200, 2), (80, -220, 2),
        (10, -290, 1.5), (150, -160, 1.5), (-130, -120, 1.5), (60, -130, 2)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.night, Theme.dusk, Theme.horizon],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(red: 0.45, green: 0.25, blue: 0.85).opacity(0.35))
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: 120, y: 380)

            Circle()
                .fill(Color(red: 0.20, green: 0.40, blue: 0.95).opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -160, y: -300)

            ForEach(0..<stars.count, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.35))
                    .frame(width: stars[index].size, height: stars[index].size)
                    .offset(x: stars[index].x, y: stars[index].y)
            }
        }
        .ignoresSafeArea()
    }
}

struct AeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

extension View {
    func aeroCard() -> some View {
        modifier(AeroCardModifier())
    }
}

struct AeroButton: View {
    let title: String
    var systemImage: String = "arrow.right"
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.sunset)
        .disabled(!isEnabled)
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct NoticeBanner: View {
    let text: String
    var isLive: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isLive ? "dot.radiowaves.left.and.right" : "info.circle.fill")
                .foregroundStyle(isLive ? Theme.mint : Theme.mango)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background((isLive ? Theme.mint : Theme.mango).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct AirplaneLoader: View {
    let text: String
    @State private var animate = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4, 6]))
                    .frame(width: 200, height: 1)
                Image(systemName: "airplane")
                    .font(.title)
                    .foregroundStyle(Theme.sunsetGradient)
                    .offset(x: animate ? 100 : -100, y: animate ? -10 : 10)
            }
            .frame(height: 44)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.sunsetGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
        }
        .frame(width: 64, height: 64)
        .animation(.easeInOut, value: progress)
    }
}

struct BoardingBarcode: View {
    let code: String

    private var widths: [CGFloat] {
        var result: [CGFloat] = []
        for letter in code.unicodeScalars {
            let value = Int(letter.value)
            result.append(CGFloat(value % 3 + 1))
            result.append(CGFloat(value % 2 + 1))
            result.append(CGFloat((value / 3) % 3 + 1))
            result.append(CGFloat((value / 5) % 2 + 1))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<widths.count, id: \.self) { index in
                    Rectangle()
                        .fill(index % 2 == 0 ? Theme.night : Theme.night.opacity(0.7))
                        .frame(width: widths[index] * 1.6, height: 52)
                }
            }
            Text(code)
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(Theme.night)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
