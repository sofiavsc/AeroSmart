//
//  WeatherViewModel.swift
//  AeroSmart
//

import Foundation
import Observation

// Consume la API de Open-Meteo con URLSession + async/await
@MainActor
@Observable
final class WeatherViewModel {
    // nil = todavía no se ha consumido la API
    var weather: Weather? = nil
    var isLoading = false
    var errorMessage: String? = nil

    func getWeather(for airport: Airport) async {
        let endPoint = "https://api.open-meteo.com/v1/forecast?latitude=\(airport.latitude)&longitude=\(airport.longitude)&current=temperature_2m,weather_code,is_day&timezone=auto"
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
                errorMessage = "No se pudo cargar el clima (\(httpResponse.statusCode))"
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode(Weather.self, from: data)
            weather = decoded
        } catch {
            // casi siempre es porque no hay Internet
            print("Error: \(error.localizedDescription)")
            errorMessage = "Sin conexión. Tu viaje sigue guardado en el teléfono."
        }
        isLoading = false
    }
}
