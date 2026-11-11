//
//  DuffelClient.swift
//  AeroSmart
//

import Foundation

// MARK: - Cliente HTTP para la API de Duffel (modo prueba)
// Mismos pasos que en la clase 11: validar URL, armar el URLRequest,
// mandar con URLSession + await y revisar el statusCode.

enum DuffelError: Error {
    case missingToken
    case http(Int)
    case badData
}

enum DuffelClient {
    // El token se escribe en Perfil y se guarda con @AppStorage("duffelToken").
    // @AppStorage usa UserDefaults por dentro, así que aquí lo leemos de ahí.
    static var token: String {
        let saved = UserDefaults.standard.string(forKey: "duffelToken") ?? ""
        return saved.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var hasToken: Bool {
        return !token.isEmpty
    }

    // path ya incluye los parámetros, por ejemplo "/air/seat_maps?offer_id=off_123"
    static func send(path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard hasToken else { throw DuffelError.missingToken }

        let endPoint = "https://api.duffel.com" + path
        guard let apiURL = URL(string: endPoint) else {
            print("Url no válida o no definida")
            throw DuffelError.badData
        }

        var urlRequest = URLRequest(url: apiURL)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        // Cabeceras que pide Duffel
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("v2", forHTTPHeaderField: "Duffel-Version")

        // Si mandamos body (POST) va en JSON
        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: sin respuesta del servidor")
            throw DuffelError.badData
        }
        // Duffel contesta 200 en los GET y 201 (Created) en el POST de búsqueda
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("Status \(httpResponse.statusCode)")
            throw DuffelError.http(httpResponse.statusCode)
        }
        return data
    }

    // Texto corto para explicarle al usuario por qué falló
    static func describe(_ error: Error) -> String {
        if let duffelError = error as? DuffelError {
            switch duffelError {
            case .missingToken:
                return "falta el token"
            case .http(let code):
                return code == 401 ? "token inválido (401)" : "error \(code)"
            case .badData:
                return "respuesta inesperada"
            }
        }
        if error is DecodingError {
            return "respuesta inesperada"
        }
        return "sin conexión o tiempo agotado"
    }
}
