import SwiftUI
import SwiftData

struct ProfileView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDestination]
    @Query private var allTrips: [Trip]

    @AppStorage("sessionEmail") private var sessionEmail = ""
    @AppStorage("duffelToken") private var duffelToken = ""
    @AppStorage("aviationstackKey") private var aviationKey = ""

    private var myFavorites: [FavoriteDestination] {
        var result: [FavoriteDestination] = []
        for favorite in favorites where favorite.ownerEmail == user.email {
            result.append(favorite)
        }
        return result
    }

    private var tripsCount: Int {
        var count = 0
        for trip in allTrips where trip.ownerEmail == user.email && !trip.isCancelled {
            count += 1
        }
        return count
    }

    private var hasToken: Bool {
        return !duffelToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        userCard
                        favoritesCard
                        apiCard
                        statusApiCard
                        aboutCard

                        Button {
                            withAnimation {
                                sessionEmail = ""
                            }
                        } label: {
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.rose.opacity(0.8))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Perfil")
        }
    }

    private var userCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.sunsetGradient)
                    .frame(width: 64, height: 64)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.title.bold())
                    .foregroundStyle(Theme.night)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title3.bold())
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 14) {
                    Label("\(tripsCount) viajes", systemImage: "airplane")
                    Label("\(myFavorites.count) favoritos", systemImage: "heart.fill")
                }
                .font(.caption)
                .foregroundStyle(Theme.sunset)
            }
            Spacer()
        }
        .aeroCard()
    }

    private var favoritesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Destinos favoritos")
                .font(.headline)

            if myFavorites.isEmpty {
                Text("Toca el corazón en un destino de la pestaña Volar para guardarlo aquí.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                ForEach(myFavorites, id: \.code) { favorite in
                    HStack {
                        Image(systemName: Airport.find(favorite.code)?.icon ?? "mappin")
                            .foregroundStyle(Theme.sunset)
                            .frame(width: 26)
                        Text("\(Airport.cityName(favorite.code)) (\(favorite.code))")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            modelContext.delete(favorite)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "heart.slash")
                                .foregroundStyle(Theme.rose)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aeroCard()
    }

    private var apiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("API de asientos y vuelos", systemImage: "network")
                    .font(.headline)
                Spacer()
                StatusPill(
                    text: hasToken ? "Duffel conectado" : "Modo demo",
                    color: hasToken ? Theme.mint : Theme.mango
                )
            }

            Text("Pega tu token de prueba de Duffel (empieza con duffel_test_) para ver vuelos y mapas de asientos reales. Sin token, la app funciona con datos de demostración.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            SecureField("duffel_test_...", text: $duffelToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let url = URL(string: "https://duffel.com") {
                Link(destination: url) {
                    Label("Crear cuenta en Duffel", systemImage: "arrow.up.right.square")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.sunset)
                }
            }
        }
        .aeroCard()
    }

    private var hasAviationKey: Bool {
        return !aviationKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var statusApiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Estatus de vuelos", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                StatusPill(
                    text: hasAviationKey ? "Conectado" : "Sin llave",
                    color: hasAviationKey ? Theme.mint : Theme.mango
                )
            }

            Text("Para ver las salidas en vivo de la pestaña En vivo, crea una cuenta gratis en Aviationstack (100 consultas al mes) y pega aquí tu Access Key. El radar de aviones no necesita llave.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            SecureField("Access Key de Aviationstack", text: $aviationKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let url = URL(string: "https://aviationstack.com") {
                Link(destination: url) {
                    Label("Crear cuenta en Aviationstack", systemImage: "arrow.up.right.square")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.sunset)
                }
            }
        }
        .aeroCard()
    }

    private var aboutCard: some View {
        HStack(spacing: 14) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: 36)
                .padding(12)
                .background(Theme.night)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 6) {
                Text("AeroSmart")
                    .font(.headline)
                Text("Proyecto semestral · Desarrollo de Aplicaciones Móviles II")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("Ana Sofia Soqui · Jacobo Castillo")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aeroCard()
    }
}
