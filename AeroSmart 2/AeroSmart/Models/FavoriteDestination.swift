//
//  FavoriteDestination.swift
//  AeroSmart
//

import Foundation
import SwiftData

@Model
final class FavoriteDestination {
    var ownerEmail: String
    var code: String

    init(ownerEmail: String, code: String) {
        self.ownerEmail = ownerEmail
        self.code = code
    }
}
