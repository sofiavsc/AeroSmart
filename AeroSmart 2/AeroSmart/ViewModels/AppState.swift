//
//  AppState.swift
//  AeroSmart
//

import Foundation
import Observation

// Estado compartido de toda la app (se comparte con .environment como en la clase 11):
// qué pestaña está abierta y un "token" para regresar el buscador al inicio después de reservar.
@MainActor
@Observable
final class AppState {
    var selectedTab = 0
    var searchResetToken = 0
}
