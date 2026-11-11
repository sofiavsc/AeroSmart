//
//  DeparturesViewModel.swift
//  AeroSmart
//

import Foundation
import Observation

// "Salidas de hoy": estatus de los vuelos que salen de un aeropuerto, con Aviationstack.
// Necesita una llave gratis (100 consultas al mes) que se pega en Perfil.
@MainActor
@Observable
final class DeparturesViewModel {
    var flights: [FlightStatus] = []
    var isLoading = false
    var errorMessage: String? = nil
    var loadedCode = ""

    func getDepartures(from airportCode: String) async {
        let key = (UserDefaults.standard.string(forKey: "aviationstackKey") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            errorMessage = "Agrega tu llave de Aviationstack en Perfil para ver las salidas en vivo."
            return
        }

        // El plan gratis de Aviationstack solo funciona con http (no https)
        let endPoint = "http://api.aviationstack.com/v1/flights?access_key=\(key)&dep_iata=\(airportCode)&limit=15"
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
                // 401 = llave incorrecta, 429 = se acabaron las consultas del mes
                if httpResponse.statusCode == 401 {
                    errorMessage = "La llave de Aviationstack no es válida."
                } else if httpResponse.statusCode == 429 {
                    errorMessage = "Se acabaron las consultas gratis del mes."
                } else {
                    errorMessage = "No se pudo cargar el estatus (\(httpResponse.statusCode))"
                }
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode(DeparturesResponse.self, from: data)
            flights = decoded.data
            loadedCode = airportCode
        } catch {
            print("Error: \(error.localizedDescription)")
            errorMessage = "Sin conexión o respuesta inesperada."
        }
        isLoading = false
    }
}
