//
//  User.swift
//  AeroSmart
//

import Foundation
import SwiftData

@Model
final class User {
    var name: String
    var email: String
    var password: String
    var createdAt: Date

    init(name: String, email: String, password: String, createdAt: Date = Date()) {
        self.name = name
        self.email = email
        self.password = password
        self.createdAt = createdAt
    }
}
