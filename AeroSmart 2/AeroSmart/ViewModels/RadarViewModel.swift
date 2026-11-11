//
//  RadarViewModel.swift
//  AeroSmart
//

import Foundation
import Observation

// "Radar": aviones volando cerca de un aeropuerto, con la API pública de OpenSky Network.
// No necesita token. OpenSky manda cada avión como un arreglo con datos de distinto tipo
// (["0d0a1b", "VOI1234 ", "Mexico", ..., 25.7, -100.1, 10668.0, false, 230.5, 45.0, ...]),
// así que no se puede usar un modelo Decodable normal. Por eso se lee a mano con
// JSONSerialization, como en el "Extra: Codificación Manual" de la clase 11.
@MainActor
@Observable
final class RadarViewModel {
    var aircraft: [LiveAircraft] = []
    var isLoading = false
    var errorMessage: String? = nil
    var loadedCode = ""

    func getAircraft(near airport: Airport) async {
        // cuadro de ~1° alrededor del aeropuerto (más o menos 110 km por lado)
        let lamin = airport.latitude - 1
        let lamax = airport.latitude + 1
        let lomin = airport.longitude - 1
        let lomax = airport.longitude + 1
        let endPoint = "https://opensky-network.org/api/states/all?lamin=\(lamin)&lomin=\(lomin)&lamax=\(lamax)&lomax=\(lomax)"

        guard let apiURL = URL(string: endPoint) else {
            print("Url no válida o no definida")
            return
        }

        var urlRequest = URLRequest(url: apiURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        isLoading = true
        errorMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Sin respuesta del servidor"
                isLoading = false
                return
            }
            guard httpResponse.statusCode == 200 else {
                // 429 = ya se gastaron las consultas gratis del día
                errorMessage = httpResponse.statusCode == 429
                    ? "El radar ya llegó a su límite de consultas por hoy. Intenta más tarde."
                    : "No se pudo cargar el radar (\(httpResponse.statusCode))"
                isLoading = false
                return
            }

            // Codificación manual
            let json = try JSONSerialization.jsonObject(with: data)
            guard let jsonData = json as? [String: Any] else {
                errorMessage = "El JSON no tiene el formato esperado"
                isLoading = false
                return
            }
            // "states" viene en null cuando no hay aviones en la zona
            let jsonArray = jsonData["states"] as? [[Any]] ?? []

            var result: [LiveAircraft] = []
            for item in jsonArray {
                if item.count < 11 { continue }
                let icao24 = item[0] as? String ?? ""
                let callsign = (item[1] as? String ?? "").trimmingCharacters(in: .whitespaces)
                let country = item[2] as? String ?? ""
                let altitude = item[7] as? Double
                let onGround = item[8] as? Bool ?? false
                let velocity = item[9] as? Double ?? 0
                let heading = item[10] as? Double ?? 0

                result.append(LiveAircraft(
                    icao24: icao24,
                    callsign: callsign.isEmpty ? "Sin nombre" : callsign,
                    country: country,
                    altitudeMeters: altitude,
                    onGround: onGround,
                    velocity: velocity,
                    heading: heading
                ))
            }

            // primero los que van volando y más alto
            result.sort { ($0.altitudeMeters ?? 0) > ($1.altitudeMeters ?? 0) }
            aircraft = Array(result.prefix(25))
            loadedCode = airport.code
        } catch {
            print("Error: \(error.localizedDescription)")
            errorMessage = "Sin conexión. Revisa tu Internet."
        }
        isLoading = false
    }
}
