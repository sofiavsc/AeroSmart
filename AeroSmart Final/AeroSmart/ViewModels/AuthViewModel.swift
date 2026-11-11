import Foundation
import SwiftData
import Observation

enum AuthResult {
    case success(User)
    case emptyFields
    case invalidEmail
    case shortPassword
    case emailTaken
    case wrongCredentials
    case saveError
}

@MainActor
@Observable
final class AuthViewModel {
    var name = ""
    var email = ""
    var password = ""

    static let demoEmail = "demo@aerosmart.mx"
    static let demoPassword = "demo123"

    private func clearFields() {
        name = ""
        email = ""
        password = ""
    }

    func register(users: [User], context: ModelContext) -> AuthResult {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if cleanName.isEmpty || cleanEmail.isEmpty || password.isEmpty {
            return .emptyFields
        }
        if !cleanEmail.contains("@") || !cleanEmail.contains(".") {
            return .invalidEmail
        }
        if password.count < 6 {
            return .shortPassword
        }
        for user in users where user.email == cleanEmail {
            return .emailTaken
        }

        let newUser = User(name: cleanName, email: cleanEmail, password: password)
        context.insert(newUser)
        do {
            try context.save()
            clearFields()
            return .success(newUser)
        } catch {
            return .saveError
        }
    }

    func login(users: [User]) -> AuthResult {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanEmail.isEmpty || password.isEmpty {
            return .emptyFields
        }
        for user in users where user.email == cleanEmail && user.password == password {
            clearFields()
            return .success(user)
        }
        return .wrongCredentials
    }

    func loginDemo(users: [User], context: ModelContext) -> AuthResult {
        for user in users where user.email == AuthViewModel.demoEmail {
            return .success(user)
        }
        let demoUser = User(
            name: "Viajera Demo",
            email: AuthViewModel.demoEmail,
            password: AuthViewModel.demoPassword
        )
        context.insert(demoUser)
        do {
            try context.save()
            return .success(demoUser)
        } catch {
            return .saveError
        }
    }

    func message(for result: AuthResult) -> (title: String, message: String) {
        switch result {
        case .success:
            return ("¡A bordo!", "Sesión iniciada correctamente.")
        case .emptyFields:
            return ("Campos vacíos", "Completa todos los campos para continuar.")
        case .invalidEmail:
            return ("Correo inválido", "Escribe un correo con formato válido, por ejemplo nombre@correo.com.")
        case .shortPassword:
            return ("Contraseña muy corta", "La contraseña debe tener al menos 6 caracteres.")
        case .emailTaken:
            return ("Correo ya registrado", "Ya existe una cuenta con ese correo. Inicia sesión.")
        case .wrongCredentials:
            return ("Datos incorrectos", "El correo o la contraseña no coinciden.")
        case .saveError:
            return ("Error", "No se pudo guardar la información.")
        }
    }
}
