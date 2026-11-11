//
//  AuthView.swift
//  AeroSmart
//

import SwiftUI
import SwiftData

struct AuthView: View {
    @Binding var sessionEmail: String

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var viewModel = AuthViewModel()
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var floating = false

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 26) {
                    logo
                    formCard
                    demoButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }

    // MARK: Logo
    private var logo: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(Theme.night)
                    .frame(width: 130, height: 130)
                    .shadow(color: Theme.lilac.opacity(0.35), radius: 28)
                RoundedRectangle(cornerRadius: 34)
                    .stroke(.white.opacity(0.6), lineWidth: 1)
                    .frame(width: 130, height: 130)
                Image("LogoMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84)
            }
            .offset(y: floating ? -6 : 6)

            Text("AeroSmart")
                .font(.system(size: 38, weight: .heavy, design: .rounded))

            Text("Despega sin pendientes")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: Formulario
    private var formCard: some View {
        VStack(spacing: 16) {
            Picker("Modo", selection: $isRegistering) {
                Text("Iniciar sesión").tag(false)
                Text("Registro").tag(true)
            }
            .pickerStyle(.segmented)

            if isRegistering {
                field(icon: "person.fill") {
                    TextField("Nombre completo", text: $viewModel.name)
                }
            }

            field(icon: "envelope.fill") {
                TextField("Correo electrónico", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }

            field(icon: "lock.fill") {
                SecureField("Contraseña", text: $viewModel.password)
            }

            AeroButton(
                title: isRegistering ? "Crear mi cuenta" : "Despegar",
                systemImage: isRegistering ? "person.badge.plus" : "airplane.departure"
            ) {
                submit()
            }
        }
        .aeroCard()
        .animation(.easeInOut, value: isRegistering)
    }

    private func field<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.mango)
                .frame(width: 22)
            content()
        }
        .padding(14)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var demoButton: some View {
        Button {
            handle(viewModel.loginDemo(users: users, context: modelContext))
        } label: {
            Label("Entrar con la cuenta demo", systemImage: "sparkles")
                .font(.subheadline.bold())
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.dusk)
    }

    // MARK: Acciones
    private func submit() {
        if isRegistering {
            handle(viewModel.register(users: users, context: modelContext))
        } else {
            handle(viewModel.login(users: users))
        }
    }

    private func handle(_ result: AuthResult) {
        switch result {
        case .success(let user):
            withAnimation {
                sessionEmail = user.email
            }
        default:
            let info = viewModel.message(for: result)
            alertTitle = info.title
            alertMessage = info.message
            showAlert = true
        }
    }
}
