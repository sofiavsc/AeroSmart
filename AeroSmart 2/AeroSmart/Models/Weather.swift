//
//  Weather.swift
//  AeroSmart
//

import Foundation

struct Weather: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature: Double
        let weatherCode: Int
        let isDay: Int

        // El JSON viene en snake_case, se renombra con CodingKeys
        private enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }
}

extension Weather.Current {
    var temperatureText: String {
        return "\(Int(temperature.rounded()))°"
    }

    var description: String {
        switch weatherCode {
        case 0: return "Despejado"
        case 1, 2: return "Algo nublado"
        case 3: return "Nublado"
        case 45, 48: return "Neblina"
        case 51...57: return "Llovizna"
        case 61...67, 80...82: return "Lluvia"
        case 71...77, 85, 86: return "Nieve"
        case 95...99: return "Tormenta"
        default: return "Clima variable"
        }
    }

    var icon: String {
        switch weatherCode {
        case 0: return isDay == 1 ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay == 1 ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    var packingTip: String {
        if weatherCode >= 51 && weatherCode <= 82 {
            return "Va a estar lloviendo, mete paraguas o impermeable."
        }
        if weatherCode >= 95 {
            return "Hay tormenta en el destino, revisa el estado de tu vuelo antes de salir."
        }
        if weatherCode >= 71 && weatherCode <= 86 {
            return "¡Hay nieve! Lleva abrigo, guantes y bufanda."
        }
        if temperature >= 28 {
            return "Hace calor, no olvides bloqueador, lentes de sol y ropa ligera."
        }
        if temperature <= 15 {
            return "Está fresco, lleva una chamarra a la mano."
        }
        return "Clima agradable, con una capa ligera vas bien."
    }
}
