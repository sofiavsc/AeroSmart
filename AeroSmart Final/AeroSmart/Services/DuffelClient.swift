import Foundation

enum DuffelError: Error {
    case missingToken
    case http(Int)
    case badData
}

enum DuffelClient {
    static var token: String {
        let saved = UserDefaults.standard.string(forKey: "duffelToken") ?? ""
        return saved.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var hasToken: Bool {
        return !token.isEmpty
    }

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
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("v2", forHTTPHeaderField: "Duffel-Version")

        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: sin respuesta del servidor")
            throw DuffelError.badData
        }
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("Status \(httpResponse.statusCode)")
            throw DuffelError.http(httpResponse.statusCode)
        }
        return data
    }

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
