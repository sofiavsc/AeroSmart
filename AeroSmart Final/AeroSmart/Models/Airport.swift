import Foundation

struct Airport {
    let code: String
    let city: String
    let name: String
    let latitude: Double
    let longitude: Double
    let icon: String
    let tagline: String

    static let all: [Airport] = [
        Airport(code: "MEX", city: "Ciudad de México", name: "Aeropuerto Internacional Benito Juárez", latitude: 19.4363, longitude: -99.0721, icon: "building.2.fill", tagline: "Museos, cultura y tacos a cualquier hora"),
        Airport(code: "MTY", city: "Monterrey", name: "Aeropuerto Internacional Mariano Escobedo", latitude: 25.7785, longitude: -100.1069, icon: "mountain.2.fill", tagline: "Montañas, cabrito y la Sultana del Norte"),
        Airport(code: "GDL", city: "Guadalajara", name: "Aeropuerto Internacional Miguel Hidalgo", latitude: 20.5218, longitude: -103.3112, icon: "music.note", tagline: "Mariachi, tequila y tradición"),
        Airport(code: "CUN", city: "Cancún", name: "Aeropuerto Internacional de Cancún", latitude: 21.0365, longitude: -86.8771, icon: "sun.max.fill", tagline: "Playas de arena blanca y mar turquesa"),
        Airport(code: "TAM", city: "Tampico", name: "Aeropuerto Internacional Francisco Javier Mina", latitude: 22.2964, longitude: -97.8659, icon: "drop.fill", tagline: "Puerto, laguna y mariscos frescos"),
        Airport(code: "TIJ", city: "Tijuana", name: "Aeropuerto Internacional de Tijuana", latitude: 32.5411, longitude: -116.9700, icon: "fork.knife", tagline: "Gastronomía de frontera y vida cultural"),
        Airport(code: "MID", city: "Mérida", name: "Aeropuerto Internacional Manuel Crescencio Rejón", latitude: 20.9370, longitude: -89.6577, icon: "leaf.fill", tagline: "Cenotes, historia maya y cochinita"),
        Airport(code: "BJX", city: "León / Bajío", name: "Aeropuerto Internacional del Bajío", latitude: 20.9935, longitude: -101.4808, icon: "figure.walk", tagline: "Guanajuato, calles de colores y arte"),
        Airport(code: "PVR", city: "Puerto Vallarta", name: "Aeropuerto Internacional Gustavo Díaz Ordaz", latitude: 20.6801, longitude: -105.2542, icon: "sailboat.fill", tagline: "Malecón, atardeceres y Pacífico"),
        Airport(code: "SJD", city: "Los Cabos", name: "Aeropuerto Internacional de Los Cabos", latitude: 23.1518, longitude: -109.7211, icon: "wave.3.right", tagline: "Desierto, mar y El Arco"),
        Airport(code: "OAX", city: "Oaxaca", name: "Aeropuerto Internacional Xoxocotlán", latitude: 16.9999, longitude: -96.7266, icon: "flame.fill", tagline: "Mole, mezcal y tradiciones vivas"),
        Airport(code: "QRO", city: "Querétaro", name: "Aeropuerto Intercontinental de Querétaro", latitude: 20.6173, longitude: -100.1856, icon: "building.columns.fill", tagline: "Centro histórico y viñedos"),
        Airport(code: "HOU", city: "Houston", name: "George Bush Intercontinental Airport", latitude: 29.9902, longitude: -95.3368, icon: "star.fill", tagline: "Espacio, negocios y buena comida"),
        Airport(code: "MIA", city: "Miami", name: "Miami International Airport", latitude: 25.7959, longitude: -80.2870, icon: "sun.haze.fill", tagline: "Sol, playa y ritmo latino"),
        Airport(code: "LAX", city: "Los Ángeles", name: "Los Angeles International Airport", latitude: 33.9416, longitude: -118.4085, icon: "camera.fill", tagline: "Cine, costa y estilo de vida"),
        Airport(code: "JFK", city: "Nueva York", name: "John F. Kennedy International Airport", latitude: 40.6413, longitude: -73.7781, icon: "building.2.crop.circle.fill", tagline: "La ciudad que nunca duerme")
    ]

    static func find(_ code: String) -> Airport? {
        for airport in all where airport.code == code {
            return airport
        }
        return nil
    }

    static func cityName(_ code: String) -> String {
        return find(code)?.city ?? code
    }

    static func distanceKm(_ a: Airport, _ b: Airport) -> Double {
        let radius = 6371.0
        let lat1 = a.latitude * Double.pi / 180
        let lat2 = b.latitude * Double.pi / 180
        let dLat = (b.latitude - a.latitude) * Double.pi / 180
        let dLon = (b.longitude - a.longitude) * Double.pi / 180
        let sinLat = sin(dLat / 2)
        let sinLon = sin(dLon / 2)
        let h = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon
        return 2 * radius * asin(min(1.0, sqrt(h)))
    }
}
