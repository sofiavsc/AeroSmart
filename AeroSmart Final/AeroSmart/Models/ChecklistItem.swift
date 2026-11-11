import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var title: String
    var detail: String
    var icon: String
    var order: Int
    var isDone: Bool
    var requiredStatus: Int
    var trip: Trip?

    init(title: String, detail: String, icon: String, order: Int, isDone: Bool, requiredStatus: Int) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.order = order
        self.isDone = isDone
        self.requiredStatus = requiredStatus
    }
}
